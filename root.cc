/****************************************************************************
*
* This is a part of the "ROOT extension to Asymptote" project.
* Authors: 
*	Jan Kašpar (jan.kaspar@gmail.com) 
*
****************************************************************************/

#include "root.h"

#include <cstdio>

#include "TClass.h"
#include "TH1.h"
#include "TGraph.h"
#include "TFile.h"
#include "TPad.h"
#include "TKey.h"

#ifdef ROOT_5
	#include "Api.h"
#endif

#ifdef ROOT_6
	#include "TInterpreter.h"
#endif

#include "errormsg.h"


using namespace mem;

//----------------------------------------------------------------------------------------------------

void RootError(string msg, bool stop = true)
{
	if (!msg.empty())
	{
		em.error(vm::getPos());
		em << "ROOT error in ";
		em << msg;
	}

	if (stop)
		throw handled_error();
}

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------

RootFileCollection RootObject::files;
string RootObject::lastMethod;
RootObject robj;

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------

RootFileCollection::RootFileCollection(unsigned int size) : std::vector<TFile *>(size)
{
}

//----------------------------------------------------------------------------------------------------

RootFileCollection::~RootFileCollection()
{
	// TODO: leads to seg fault with ROOT 6
	//for (unsigned int i = 0; i < size(); ++i)
	//.	delete at(i);
	
	clear();
}

//----------------------------------------------------------------------------------------------------

TFile* RootFileCollection::Get(const string file, bool errorIfNotExisting)
{
	// first, check whether the file is already opened
	TFile *f = NULL;
	for (unsigned int i = 0; i < size(); ++i)
	{
		if (!file.compare(at(i)->GetName()))
		{
			f = at(i);
			break;
		}
	}
	
	// if not opened, open it now
	if (!f)
	{
		f = TFile::Open(file.c_str());
		if (!f)
			RootError("RootFileCollection::Get > Cannot open file `" + file + "'.", errorIfNotExisting);
		else
			push_back(f);
	}

	return f;
}

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------

RootObject::RootObject(TObject *o) : obj(o), releaseObj(false)
{
}

//----------------------------------------------------------------------------------------------------

RootObject::RootObject(const RootObject &copy)
{
	obj = copy.obj;
	releaseObj = false;
}

//----------------------------------------------------------------------------------------------------

RootObject::~RootObject()
{
	if (releaseObj)
		delete obj;
}

//----------------------------------------------------------------------------------------------------

RootObject* RootObject::Copy()
{
	if (!obj)
		RootError("RootObject::Copy > Object points to NULL.", true);

	TObject *o = obj->Clone();
	RootObject *ro = new RootObject(o);
	ro->releaseObj = true;
	return ro;
}

//----------------------------------------------------------------------------------------------------

bool RootObject::IsValid()
{
	return (obj != NULL);
}

//----------------------------------------------------------------------------------------------------

TObject* RootObject::GetFromFileSafe(TFile *f, const string &path, bool errorIfNotExisting)
{
	// the normal way
	TObject *o = f->Get(path.c_str());
	if (o)
		return o;

	// avoid ROOT bugs, load directories one by one
	//printf(">> RootObject::GetFromFileSafe(%p, %s) > Trying to load directories one by one.\n", f, path.c_str());

	TDirectory *d = f;
	size_t idx_s = 0;
	while (true)
	{
		size_t idx_e = path.find_first_of("/", idx_s);
		
		string bit = path.substr(idx_s, idx_e-idx_s);
		
		o = d->Get(bit.c_str());
		//printf("%s -> %p\n", bit.c_str(), o);

		if (!o)
		{
			if (errorIfNotExisting)
				RootError("RootObject::GetFromFileSafe > object `"+bit+"' does not exist.", false);
			return NULL;
		}

		if (idx_e != string::npos)
		{
			if (! o->InheritsFrom("TDirectory") )
			{
				if (errorIfNotExisting)
					RootError("RootObject::GetFromFileSafe > object `"+bit+"' is not a directory.", false);
				return NULL;
			}

			d = (TDirectory *) o;
		} else {
			break;
		}

		idx_s = idx_e+1;
	}

	return o;
}

//----------------------------------------------------------------------------------------------------

RootObject* RootObject::GetFromFile(string file, string name, bool errorIfNotExisting, bool searchInCollections)
{
	// create new (empty/invalid) instance of RootObject
	RootObject *obj = new RootObject();

	// objects are owned by the file
	obj->releaseObj = false;

	// get/open file
	TFile *f = files.Get(file, errorIfNotExisting);
	if (!f)
		return obj;

	// extract name(s) of collection(s) and object(s) in it(them)
	vector<string> names;
	vector<bool> isNameIndex;
	if (searchInCollections)
	{
		while (true)
		{
			size_t idx = name.find_first_of("#|");
			if (idx != string::npos)
			{
				isNameIndex.push_back((name[idx] == '#') ? true : false);
				names.push_back(name.substr(0, idx));
				name = name.substr(idx+1);
			} else {
				names.push_back(name);
				break;
			}
		}
	} else {
		names.push_back(name);
	}

	TList *list = NULL;
	for (unsigned int i = 0; i < names.size(); i++)
	{
		if (i == 0)
		{
			// get from file
			obj->obj = GetFromFileSafe(f, names[i], errorIfNotExisting);
			if (!obj->obj)
			{
				if (errorIfNotExisting)
				{
					RootError("RootObject::GetFromFile > No object `" + names[i] + "' in file `" + file + "'.", false);
					printf("\n");

					// determine the last existing directory
					TDirectory *dir = f;
					size_t idx = 0;
					string dir_name = ".";
					while (true)
					{
						idx = names[i].find_first_of("/", idx);
						if (idx != string::npos)
						{
							string test = names[i].substr(0, idx);
							TObject *o = GetFromFileSafe(f, test, errorIfNotExisting);
							if (o)
							{
								if (o->InheritsFrom("TDirectory"))
								{
									dir = (TDirectory *) o;
									dir_name = test;
									idx++;
								} else {
									printf("Object `%s' exits, but is not a directory.\n", test.c_str());
									dir = NULL;
									break;
								}
							} else
								break;
						} else
							break;
					}

					if (dir)
					{
						printf("    The directory `%s' contains the following objects only (class, name):\n", dir_name.c_str());

						TIter next(dir->GetListOfKeys());
						while (TObject *iobj = next())
						{
							TKey *key = (TKey *) iobj;
							printf("\t%s\t`%s'\n", key->GetClassName(), iobj->GetName());
							i++;
						}
					}

					RootError("", true);
				}
				return obj;
			}
		} else {
			obj->obj = NULL;
			// get from collection
			if (isNameIndex[i - 1])
			{
				obj->obj = list->At(atoi(names[i].c_str()));
			} else {
				TIter next(list);
				while (TObject *iobj = next())
				{
					if (!names[i].compare(iobj->GetName()))
					{
						obj->obj = iobj;
						break;
					}
				}
			}
	
			if (!obj->obj)
			{
				if (errorIfNotExisting)
				{
					// print items in the collection
					RootError("RootObject::GetFromFile > Object with " + string((isNameIndex[i - 1]) ? "index" : "name") + 
						" '" + names[i] + "' not found in the collection.", false);
					printf("    The collection (from `%s') contains only the following items (index, class, name):\n",
						names[i-1].c_str());
					TIter next(list);
					unsigned int i = 0;
					while (TObject *iobj = next())
					{
						printf("\t%u\t%s\t`%s'\n", i, iobj->IsA()->GetName(), iobj->GetName());
						i++;
					}
					
					RootError("", true);
				}

				return obj;
			}
		}

		// we're at the end of the chain
		if (i == names.size() - 1)
			break;

		// get the list of the given object
		list = NULL;
		if (obj->obj->IsA()->InheritsFrom("TList"))
			list = (TList *) obj->obj;
		if (obj->obj->IsA()->InheritsFrom("TPad"))
			list = ((TPad *) obj->obj)->GetListOfPrimitives();
		if (obj->obj->IsA()->InheritsFrom("TGraph"))
			list = ((TGraph *) obj->obj)->GetListOfFunctions();
		if (obj->obj->IsA()->InheritsFrom("TH1"))
			list = ((TH1 *) obj->obj)->GetListOfFunctions();

		if (!list)
		{
			if (errorIfNotExisting)
				RootError("RootObject::GetFromFile > Object `" + name + "' of type `" + obj->obj->IsA()->GetName() + 
					"' is not a recognized collection type.");
			obj->obj = NULL;
			return obj;
		}
	}

	robj = *obj;
	return obj;
}

//----------------------------------------------------------------------------------------------------

vm::array* RootObject::GetListOf(string file, string baseDir, bool includeDirectories,
		bool includeObjects)
{
	// get base directory
	TFile *f = files.Get(file);
	TDirectory *base = NULL;
	if (baseDir.compare("/") == 0)
	{
		base = f;
	} else {
		TObject *o = GetFromFileSafe(f, baseDir);
		if (!o)
			RootError("RootObject::GetListOfDirectories > No object with name `" + baseDir + "'.");
		if (!o->InheritsFrom("TDirectory"))
			RootError("RootObject::GetListOfDirectories > Object `" + baseDir + "' is not a directory.");
		base = (TDirectory *) o;
	}

	// make the list
	TObject *o;
	TIter next(base->GetListOfKeys());
	vm::array *a = new vm::array();
	while ((o = next()))
	{
		TKey *k = (TKey *) o;
		bool folder = k->IsFolder();

		if ((includeDirectories && folder) || (includeObjects && !folder))
			a->push_back(string(k->GetName()));
	}
	
	return a;
}

//----------------------------------------------------------------------------------------------------

void RootObject::Print()
{
	printf("RootObject::Print > obj at %p\n", obj);
	if (!obj)
		return;
	printf("\tclass=`%s', name=`%s'\n", obj->IsA()->GetName(), obj->GetName());
}

//----------------------------------------------------------------------------------------------------

void RootObject::Write()
{
	if (!obj)
		printf("RootObject @ NULL\n");
	else
		printf("%s `%s' @ %p\n", obj->IsA()->GetName(), obj->GetName(), obj);
}

//----------------------------------------------------------------------------------------------------

bool RootObject::InheritsFrom(const mem::string &className)
{
	return obj->IsA()->InheritsFrom(className.c_str());
}

//----------------------------------------------------------------------------------------------------

#ifdef ROOT_5

G__value RootObject::Exec(vm::stack *Stack)
{
	using namespace vm;

	// check obj validity
	if (!obj)
	{
		RootError("RootObject::Exec > RootObject is invalid.");
		return G__null;
	}

	// get parameters
	item it = Stack->pop();
	if (it.type() != typeid(array))
	{
		RootError("RootObject::Exec > Top stack item is not array.");
		return G__null;
	}
	const array &pars = get<array>(it);

	// check number of parameters, there must be at least the method name
	G__param parameters;
	parameters.paran = pars.size() - 1;
	if (parameters.paran < 0)
	{
		RootError("RootObject::Exec > you must give at least one parameter - method name.");
		return G__null;
	}

	// get parameters
	string signature;
	for (unsigned int i = 0; i < pars.size() - 1; i++)
	{
		const item &it = pars[i + 1];

		if (signature.size())
			signature = signature + ", ";

		// standard values
		parameters.para[i].ref = 0;
		parameters.para[i].tagnum = -1;
		parameters.para[i].typenum = -1;

		if (it.type() == typeid(bool))
		{
			parameters.para[i].type = 'l';
			parameters.para[i].obj.i = (long) get<bool>(it);
			signature += "bool";
			continue;
		}

		if (it.type() == typeid(Int))
		{
			parameters.para[i].type = 'l';
			parameters.para[i].obj.i = (long) get<Int>(it);
			signature += "int";
			continue;
		}

		if (it.type() == typeid(double))
		{
			parameters.para[i].type = 'd';
			parameters.para[i].obj.d = get<double>(it);
			signature += "double";
			continue;
		}

		if (it.type() == typeid(mem::string))
		{
			long l = (long) get<mem::string>(it).c_str();
			parameters.para[i].type = 'C';
			parameters.para[i].ref = l;
			parameters.para[i].obj.i = l;
			signature += "const char*";
			continue;
		}
		
		if (it.type() == typeid(RootObject))
		{
			long l = (long) get<RootObject>(it).obj;
			parameters.para[i].type = 's';
			parameters.para[i].obj.i = l;
			signature += "TObject*";
			continue;
		}

		if (it.type() == typeid(vm::array))
		{
			vm::array *a = (array *) it.p;
			if (a->size() != 1)
			{
				RootError("RootObject::Exec > only arrays of size 1 are supported (as variables passed by reference).");
				continue;
			}

			const item &ai = (*a)[0];

			if (ai.type() == typeid(Int))
			{
				parameters.para[i].ref = (long) &(ai.i);
				parameters.para[i].type = 'l';
				parameters.para[i].obj.i = ai.i;
				signature += "int&";
				continue;
			}

			if (ai.type() == typeid(double))
			{
				parameters.para[i].ref = (long) &(ai.x);
				parameters.para[i].type = 'd';
				parameters.para[i].obj.d = ai.x;
				signature += "double&";
				continue;
			}

			RootError("RootObject::Exec > arrays of type " + string(ai.type().name()) + " are not supported.");
			continue;
		}

		RootError("RootObject::Exec > unsupported type: " + string(it.type().name()));
	}

	// get method name
	it = pars[0];
	if (it.type() != typeid(mem::string))
	{
		RootError("RootObject::Exec > first parameter must be a string (method name), you gave " + string(it.type().name()));
		return G__null;
	}
	string method = get<string>(it);
	lastMethod = obj->IsA()->GetName();
	lastMethod += "::" + method + "(" + signature + ")";

	// get method reference
	long offset;
	G__ClassInfo *clInfo = (G__ClassInfo*) obj->IsA()->GetClassInfo();
	G__MethodInfo mtInfo = clInfo->GetMethod(method.c_str(), &parameters, &offset);
	if (!mtInfo.Handle())
	{
		RootError("RootObject::Exec > no " + lastMethod + " method found.");
		return G__null;
	}
	
	G__CallFunc func;
	func.SetFunc(mtInfo);
	func.SetArgs(parameters);

	// calculate address
	void *address = obj->IsA()->DynamicCast(TObject::Class(), obj, kFALSE);
	address = (void*)((Long_t)address + offset);

	// eventually, call the method
	return func.Execute(address);
}

//----------------------------------------------------------------------------------------------------

void RootObject::PrintG__valueInfo(const G__value &v)
{
	char typeStr[2];
	typeStr[0] = v.type; typeStr[1] = 0;
	printf("\n\ttype = `%s' (%i)\n", typeStr, v.type);
	//printf("\ttagnum = %i\n", v.tagnum);
	//printf("\ttypenum = %i\n", v.typenum);
	G__TypeInfo tInfo(v);
	printf("\ttypeinfo.Name = %s\n", tInfo.Name());
	//printf("\ttypeinfo.TrueName = %s\n", tInfo.TrueName());

	printf("\tint = %li\n", v.obj.i);
	printf("\tdouble = %E\n", v.obj.d);
	//printf("\tref = %li\n", v.ref);

	if (v.type == 67)
		printf("\tstring = %s\n", (const char*) v.obj.i);
	if (v.type == 85)
	{
		TObject *o = (TObject *) v.obj.i;
		printf("\tTObject, class = %s, name = %s\n", o->IsA()->GetName(), o->GetName());
	}
}

//----------------------------------------------------------------------------------------------------

double RootObject::rArrayExec(string method, int index)
{
	lastMethod = obj->IsA()->GetName();
	lastMethod += "::" + method + "()";

	// get method reference
	G__param parameters;
	parameters.paran = 0;

	long offset;
	G__ClassInfo *clInfo = (G__ClassInfo*) obj->IsA()->GetClassInfo();
	G__MethodInfo mtInfo = clInfo->GetMethod(method.c_str(), &parameters, &offset);
	if (!mtInfo.Handle())
	{
		RootError("RootObject::Exec > no " + lastMethod + " method found.");
		return 0.;
	}
	
	G__CallFunc func;
	func.SetFunc(mtInfo);
	func.SetArgs(parameters);

	// calculate address
	void *address = obj->IsA()->DynamicCast(TObject::Class(), obj, kFALSE);
	address = (void*)((Long_t)address + offset);

	// call the method
	G__value ret = func.Execute(address);

	// return the array element
	double *array = (double *) ret.obj.i;
	return array[index];
}

#endif

//----------------------------------------------------------------------------------------------------

#ifdef ROOT_6

int RootObject::Exec(vm::stack *Stack, void *result)
{
	using namespace vm;

	// check obj validity
	if (!obj)
	{
		RootError("RootObject::Exec > RootObject is invalid.");
		return 1;
	}

	// get parameters
	item it = Stack->pop();
	if (it.type() != typeid(array))
	{
		RootError("RootObject::Exec > Top stack item is not array.");
		return 2;
	}
	const array &pars = get<array>(it);

	// check number of parameters, there must be at least the method name
	if (pars.size() < 1)
	{
		RootError("RootObject::Exec > you must give at least one parameter - method name.");
		return 3;
	}

	// get parameters and build signature
	vector<void *> parameters;
	string signature;
	for (unsigned int i = 0; i < pars.size() - 1; i++)
	{
		const item &it = pars[i + 1];

		if (signature.size())
			signature = signature + ",";

		if (it.type() == typeid(bool))
		{
			parameters.push_back((void *) &it.b);
			signature += "bool";
			continue;
		}

		if (it.type() == typeid(Int))
		{
			parameters.push_back((void *) &it.i);
			signature += "int";
			continue;
		}

		if (it.type() == typeid(double))
		{
			parameters.push_back((void *) &it.x);
			signature += "double";
			continue;
		}

		if (it.type() == typeid(mem::string))
		{
			// TODO: make it work, then fix TODO in drawTH1 in base/root.asy
			//auto t = get<mem::string>(it);
			//printf("[%s]\n", t.c_str());

			const char *buf = "width";

			//mem::string *str = (mem::string *) it.p;
			//parameters.push_back((void *) str->c_str());
			parameters.push_back((void *) &buf);
			signature += "char*";
			continue;
		}
		
		if (it.type() == typeid(RootObject))
		{
			parameters.push_back((void *) it.p);
			signature += obj->IsA()->GetName();
			signature += "*";
			continue;
		}

		if (it.type() == typeid(vm::array))
		{
			vm::array *a = (array *) it.p;
			if (a->size() != 1)
			{
				RootError("RootObject::Exec > only arrays of size 1 are supported (as variables passed by reference).");
				continue;
			}

			const item &ai = (*a)[0];

			if (ai.type() == typeid(Int))
			{
				parameters.push_back((void *) &ai.i);
				signature += "int&";
				continue;
			}

			if (ai.type() == typeid(double))
			{
				parameters.push_back((void *) &ai.x);
				signature += "double&";
				continue;
			}

			RootError("RootObject::Exec > arrays of type " + string(ai.type().name()) + " are not supported.");
			continue;
		}

		RootError("RootObject::Exec > unsupported type: " + string(it.type().name()));
	}

	// get method name
	it = pars[0];
	if (it.type() != typeid(mem::string))
	{
		RootError("RootObject::Exec > first parameter must be a string (method name), you gave " + string(it.type().name()));
		return 4;
	}
	string method = get<string>(it);
	lastMethod = obj->IsA()->GetName();
	lastMethod += "::" + method + "(" + signature + ")";

	// run the method
	ClassInfo_t* clInfo = obj->IsA()->GetClassInfo();
	CallFunc_t* callFunc = gInterpreter->CallFunc_Factory();

	Long_t offset;
	gInterpreter->CallFunc_SetFuncProto(callFunc, clInfo, method.c_str(), signature.c_str(), &offset);

	if (! gInterpreter->CallFunc_IsValid(callFunc) )
	{
		RootError("RootObject::Exec > no " + lastMethod + " method found.");
		return 5;
	}
 
	TInterpreter::CallFuncIFacePtr_t faceptr = gInterpreter->CallFunc_IFacePtr(callFunc);

    faceptr.fGeneric(obj, parameters.size(), parameters.data(), result);

	return 0;
}

//----------------------------------------------------------------------------------------------------

double RootObject::rArrayExec(string method, int index)
{
	// check obj validity
	if (!obj)
	{
		RootError("RootObject::rArrayExec > RootObject is invalid.");
		return 0.;
	}

	// run the method
	ClassInfo_t* clInfo = obj->IsA()->GetClassInfo();
	CallFunc_t* callFunc = gInterpreter->CallFunc_Factory();

	Long_t offset;
	gInterpreter->CallFunc_SetFuncProto(callFunc, clInfo, method.c_str(), "", &offset);

	lastMethod = obj->IsA()->GetName();
	lastMethod += "::" + method + "()";
	if (! gInterpreter->CallFunc_IsValid(callFunc) )
	{
		RootError("RootObject::Exec > no " + lastMethod + " method found.");
		return 0.;
	}
 
	TInterpreter::CallFuncIFacePtr_t faceptr = gInterpreter->CallFunc_IFacePtr(callFunc);

	vector<void *> parameters;
	double *ret = NULL;
    faceptr.fGeneric(obj, parameters.size(), parameters.data(), &ret);

	// return the array member
	return ret[index];
}

#endif

/****************************************************************************
*
* This is a part of the "ROOT extension to Asymptote" project.
* Authors: 
*	Jan Kašpar (jan.kaspar@gmail.com) 
*
****************************************************************************/

#ifndef _root_h_
#define _root_h_

#include "RVersion.h"

#if ROOT_VERSION_CODE < ROOT_VERSION(6,0,0)
	#define ROOT_5
#endif

#if ROOT_VERSION_CODE >= ROOT_VERSION(6,0,0)
	#define ROOT_6
#endif

#include <vector>

#include "memory.h"
#include "array.h"
#include "gc_cpp.h"
#include "stack.h"
#include "callable.h"

#ifdef ROOT_5
	#include "G__ci.h"
#endif

class TFile;
class TObject;

//----------------------------------------------------------------------------------------------------

/**
 *\brief A collection of ROOT files.
 **/
class RootFileCollection : public std::vector<TFile *>
{
	public:
		RootFileCollection(unsigned int size = 0);
		~RootFileCollection();

		TFile* Get(const string s, bool errorIfNotExisting = true);
};

//----------------------------------------------------------------------------------------------------

/**
 *\brief Asymptote wrapper for ROOT objects.
 **/
class RootObject : public gc
{
	protected:
		/// pointer to the ROOT object
		TObject *obj;

		/// whether to release the 'obj' at destruction time
		bool releaseObj;
	
		/// collection of opened ROOT files
		static RootFileCollection files;

	public:
		/// default constructor
		RootObject(TObject *o = NULL);

		/// copy constructor
		/// performs a shallow copy - only the pointer is copied
		RootObject(const RootObject&);

		/// destructor
		/// releases the 'obj', if needed
		~RootObject();

		/// returns a deep copy
		/// the ROOT object is copied and the new pointer is returned, the only case when
		/// releaseObj is set to true
		RootObject* Copy();

		/// loads an object from a ROOT file
		///\param errorIfNotExisting if error shall be raised if the object doesn't exist (it returns "empty" RootObject otherwise)
		///\param searchInCollections whether to search in collection
		///			(turn off if you have ROOT object the name of which contain the special characters)
		static RootObject* GetFromFile(mem::string file, mem::string name, bool errorIfNotExisting = true, bool searchInCollections = true);

		/// a wrapper for TFile::Get to overcome certain bug(s) in ROOT
		static TObject* GetFromFileSafe(TFile *f, const string &obj, bool errorIfNotExisting = true);

		/// returs the list of subdirectories or objects (or both) in the given file and directory
		static vm::array* GetListOf(string file, string baseDir, bool includeDirectories, bool includeObjects);

		/// checks whether obj is not NULL
		bool IsValid();

		/// prints information about self
		void Print();

		/// prints basic information about the object
		void Write();

		/// checks whether the obj object inherits from the given class
		bool InheritsFrom(const mem::string &className);

		//---------------------- methods to call memeber functions ------------------
		
#ifdef ROOT_5
		G__value Exec(vm::stack *Stack); 

		static void vExec(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(vExecHelper), callee));
		}

		static void vExecHelper(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			callee->Exec(Stack);
		}

		#define EXEC_DEF(prefix, Type, typeCode, typeName, unionMember, defaultValue) \
		static void prefix##Exec(vm::stack *Stack) \
		{ \
			RootObject *callee = vm::pop<RootObject *>(Stack); \
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(prefix##ExecHelper), callee)); \
		} \
		static void prefix##ExecHelper(vm::stack *Stack) \
		{ \
			RootObject *callee = vm::pop<RootObject *>(Stack); \
			G__value ret = callee->Exec(Stack); \
			if (ret.type == typeCode) \
			{ \
				Stack->push<Type>(Type(ret.obj.unionMember)); \
				return; \
			} \
			em.error(vm::getPos()); \
			em << "ERROR in RootObject::" #prefix "ExecHelper > method `" << lastMethod << "' returned value which is not " typeName "."; \
			PrintG__valueInfo(ret); \
			Stack->push<Type>(defaultValue); \
		} 

		EXEC_DEF(b, bool, 'i', "a bool", i, false)
		EXEC_DEF(i, Int, 'i', "an int", i, 0)
		EXEC_DEF(r, double, 'd', "a double", d, 0.)

		static void sExec(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(sExecHelper), callee));
		}

		static void sExecHelper(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			G__value ret = callee->Exec(Stack);
			if (ret.type == 'C')
			{
				Stack->push<mem::string>((const char *)ret.obj.i);
				return;
			}
			em.error(vm::getPos());
			em << "ERROR in RootObject::sExecHelper > method `" << lastMethod << "' returned value which is not a string.";
			PrintG__valueInfo(ret);
			Stack->push<mem::string>("");
		} 


		static void oExec(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(oExecHelper), callee));
		}

		static void oExecHelper(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			G__value ret = callee->Exec(Stack);

			//printf(">> oExecHelper: type = %i\n", ret.type);
			//PrintG__valueInfo(ret);

			if (ret.type == 'U')
			{
				Stack->push<RootObject *>( new RootObject((TObject *) ret.obj.i) );
				return;
			}

			em.error(vm::getPos());
			em << "ERROR in RootObject::sExecHelper > method `" << lastMethod << "' returned value which is not a TObject.";
			PrintG__valueInfo(ret);
			Stack->push<RootObject *>(new RootObject());
		} 

		#undef EXEC_DEF
#endif

#ifdef ROOT_6
		int Exec(vm::stack *Stack, void *result);

		static void vExec(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(vExecHelper), callee)); \
		}

		static void vExecHelper(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			callee->Exec(Stack, NULL);
		}

		#define EXEC_DEF(prefix, Type, defaultValue) \
		static void prefix##Exec(vm::stack *Stack) \
		{ \
			RootObject *callee = vm::pop<RootObject *>(Stack); \
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(prefix##ExecHelper), callee)); \
		} \
		static void prefix##ExecHelper(vm::stack *Stack) \
		{ \
			RootObject *callee = vm::pop<RootObject *>(Stack); \
			Type ret = defaultValue; \
			callee->Exec(Stack, (void *) &ret); \
			Stack->push<Type>(ret); \
		}

		EXEC_DEF(b, bool, false)
		EXEC_DEF(i, Int, 0)
		EXEC_DEF(r, double, 0.)

		static void sExec(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(sExecHelper), callee));
		}

		static void sExecHelper(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			char *ret = NULL;
			callee->Exec(Stack, (void *) &ret);
			Stack->push<mem::string>((const char *) ret);
		} 

		static void oExec(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			Stack->push<vm::callable*>(new vm::thunk(new vm::bfunc(oExecHelper), callee));
		}

		static void oExecHelper(vm::stack *Stack)
		{
			RootObject *callee = vm::pop<RootObject *>(Stack);
			TObject *ret = NULL;
			callee->Exec(Stack, (void *) &ret);
			Stack->push<RootObject *>( new RootObject((TObject *) ret) );
		} 

		#undef EXEC_DEF
#endif

	private:
		/// the name of the last (ROOT) method called by any of ?Exec methods
		static mem::string lastMethod;

#ifdef ROOT_5
		/// prints information about the given G__value
		static void PrintG__valueInfo(const G__value &);
#endif
};


/// reference to last loaded (by GetFromFile) object
extern RootObject robj;

#endif

/* -----------------------------------------------------------------------------
 * pycontainer.swg
 *
 * Python sequence <-> C++ container wrapper
 *
 * This wrapper, and its iterator, allows a general use (and reuse) of
 * the mapping between C++ and Python, thanks to the C++ templates.
 *
 * Of course, it needs the C++ compiler to support templates, but
 * since we will use this wrapper with the STL containers, that should
 * be the case.
 * ----------------------------------------------------------------------------- */

%{
#include <iostream>

#if PY_VERSION_HEX >= 0x03020000
# define SWIGPY_SLICEOBJECT PyObject
#else
# define SWIGPY_SLICEOBJECT PySliceObject
#endif
%}


#if !defined(SWIG_NO_EXPORT_ITERATOR_METHODS)
# if !defined(SWIG_EXPORT_ITERATOR_METHODS)
#  define SWIG_EXPORT_ITERATOR_METHODS SWIG_EXPORT_ITERATOR_METHODS
# endif
#endif

%include <pyiterators.swg>

/**** The PySequence C++ Wrap ***/

%fragment("<stdexcept>");

%include <std_except.i>

%fragment("container_owner_attribute_init", "init") {
  // thread safe initialization
  swig::container_owner_attribute();
}

%fragment("reference_container_owner", "header", fragment="container_owner_attribute_init") {
namespace swig {
  static PyObject* container_owner_attribute() {
    static PyObject* attr = SWIG_Python_str_FromChar("__swig_container");
    return attr;
  }

  template <typename T>
  struct container_owner {
    // By default, do not add the back-reference (for value types)
    // Specialization below will check the reference for pointer types.
    static bool back_reference(PyObject* /*child*/, PyObject* /*owner*/) {
      return false;
    }
  };

  template <>
  struct container_owner<swig::pointer_category> {  
    /*
     * Call to add a back-reference to the owning object when returning a 
     * reference from a container.  Will only set the reference if child
     * is a SWIG wrapper object that does not own the pointer.
     *
     * returns whether the reference was set or not
     */
    static bool back_reference(PyObject* child, PyObject* owner) {
      SwigPyObject* swigThis = SWIG_Python_GetSwigThis(child);
      if (swigThis && (swigThis->own & SWIG_POINTER_OWN) != SWIG_POINTER_OWN) {
        return PyObject_SetAttr(child, container_owner_attribute(), owner) != -1;
      }
      return false;
    }
  };
}
}

%fragment(SWIG_Traits_frag(swig::SwigPtr_PyObject),"header",fragment="StdTraits") {
namespace swig {
  template <>  struct traits<SwigPtr_PyObject > {
    typedef value_category category;
    static const char* type_name() { return  "SwigPtr_PyObject"; }
  };
  
  template <>  struct traits_from<SwigPtr_PyObject> {
    typedef SwigPtr_PyObject value_type;
    static PyObject *from(const value_type& val) {
      PyObject *obj = static_cast<PyObject *>(val);
      SWIG_Py_XINCREF(obj);
      return obj;
    }
  };
  
  template <> 
  struct traits_check<SwigPtr_PyObject, value_category> {
    static bool check(SwigPtr_PyObject) {
      return true;
    }
  };
  
  template <>  struct traits_asval<SwigPtr_PyObject > {   
    typedef SwigPtr_PyObject value_type;
    static int asval(PyObject *obj, value_type *val) {
      if (val) *val = obj;
      return SWIG_OK;
    }
  };
}
}

%fragment(SWIG_Traits_frag(swig::SwigVar_PyObject),"header",fragment="StdTraits") {
namespace swig {
  template <>  struct traits<SwigVar_PyObject > {
    typedef value_category category;
    static const char* type_name() { return  "SwigVar_PyObject"; }
  };
  
  template <>  struct traits_from<SwigVar_PyObject> {
    typedef SwigVar_PyObject value_type;
    static PyObject *from(const value_type& val) {
      PyObject *obj = static_cast<PyObject *>(val);
      SWIG_Py_XINCREF(obj);
      return obj;
    }
  };
  
  template <> 
  struct traits_check<SwigVar_PyObject, value_category> {
    static bool check(SwigVar_PyObject) {
      return true;
    }
  };
  
  template <>  struct traits_asval<SwigVar_PyObject > {   
    typedef SwigVar_PyObject value_type;
    static int asval(PyObject *obj, value_type *val) {
      if (val) *val = obj;
      return SWIG_OK;
    }
  };
} 
}

%fragment("SwigPySequence_Base","header",fragment="<stddef.h>",fragment="StdTraits")
{
%#include <functional>

namespace std {
  template <>
  struct less <PyObject *>
  {
    bool
    operator()(PyObject * v, PyObject *w) const
    { 
      bool res;
      SWIG_PYTHON_THREAD_BEGIN_BLOCK;
      res = PyObject_RichCompareBool(v, w, Py_LT) ? true : false;
      /* This may fall into a case of inconsistent
               eg. ObjA > ObjX > ObjB
               but ObjA < ObjB
      */
      if( PyErr_Occurred() && PyErr_ExceptionMatches(PyExc_TypeError) )
      {
        /* Objects can't be compared, this mostly occurred in Python 3.0 */
        /* Compare their ptr directly for a workaround */
        res = (v < w);
        PyErr_Clear();
      }
      SWIG_PYTHON_THREAD_END_BLOCK;
      return res;
    }
  };

  template <>
  struct less <swig::SwigPtr_PyObject>
  {
    bool
    operator()(const swig::SwigPtr_PyObject& v, const swig::SwigPtr_PyObject& w) const
    {
      return std::less<PyObject *>()(v, w);
    }
  };

  template <>
  struct less <swig::SwigVar_PyObject>
  {
    bool
    operator()(const swig::SwigVar_PyObject& v, const swig::SwigVar_PyObject& w) const
    {
      return std::less<PyObject *>()(v, w);
    }
  };

}

namespace swig {
  template <> struct traits<PyObject *> {
    typedef value_category category;
    static const char* type_name() { return "PyObject *"; }
  };  

  template <>  struct traits_asval<PyObject * > {   
    typedef PyObject * value_type;
    static int asval(PyObject *obj, value_type *val) {
      if (val) *val = obj;
      return SWIG_OK;
    }
  };

  template <> 
  struct traits_check<PyObject *, value_category> {
    static bool check(PyObject *) {
      return true;
    }
  };

  template <>  struct traits_from<PyObject *> {
    typedef PyObject * value_type;
    static PyObject *from(const value_type& val) {
      SWIG_Py_XINCREF(val);
      return val;
    }
  };
  
}

namespace swig {
  template <class Difference>
  inline size_t
  check_index(Difference i, size_t size, bool insert = false) {
    if ( i < 0 ) {
      if ((size_t) (-i) <= size)
	return (size_t) (i + size);
    } else if ( (size_t) i < size ) {
      return (size_t) i;
    } else if (insert && ((size_t) i == size)) {
      return size;
    }
    throw std::out_of_range("index out of range");
  }

  template <class Difference>
  void
  slice_adjust(Difference i, Difference j, Py_ssize_t step, size_t size, Difference &ii, Difference &jj, bool insert = false) {
    if (step == 0) {
      throw std::invalid_argument("slice step cannot be zero");
    } else if (step > 0) {
      // Required range: 0 <= i < size, 0 <= j < size, i <= j
      if (i < 0) {
        ii = 0;
      } else if (i < (Difference)size) {
        ii = i;
      } else if (insert && (i >= (Difference)size)) {
        ii = (Difference)size;
      }
      if (j < 0) {
        jj = 0;
      } else {
        jj = (j < (Difference)size) ? j : (Difference)size;
      }
      if (jj < ii)
        jj = ii;
    } else {
      // Required range: -1 <= i < size-1, -1 <= j < size-1, i >= j
      if (i < -1) {
        ii = -1;
      } else if (i < (Difference) size) {
        ii = i;
      } else if (i >= (Difference)(size-1)) {
        ii = (Difference)(size-1);
      }
      if (j < -1) {
        jj = -1;
      } else {
        jj = (j < (Difference)size ) ? j : (Difference)(size-1);
      }
      if (ii < jj)
        ii = jj;
    }
  }

  template <class Sequence, class Difference>
  inline typename Sequence::iterator
  getpos(Sequence* self, Difference i)  {
    typename Sequence::iterator pos = self->begin();
    std::advance(pos, check_index(i,self->size()));
    return pos;
  }

  template <class Sequence, class Difference>
  inline typename Sequence::const_iterator
  cgetpos(const Sequence* self, Difference i)  {
    typename Sequence::const_iterator pos = self->begin();
    std::advance(pos, check_index(i,self->size()));
    return pos;
  }

  template <class Sequence>
  inline void
  erase(Sequence* seq, const typename Sequence::iterator& position) {
    seq->erase(position);
  }

  template <class Sequence>
  struct traits_reserve {
    static void reserve(Sequence & /*seq*/, typename Sequence::size_type /*n*/) {
      // This should be specialized for types that support reserve
    }
  };

  template <class Sequence, class Difference>
  inline Sequence*
  getslice(const Sequence* self, Difference i, Difference j, Py_ssize_t step) {
    typename Sequence::size_type size = self->size();
    Difference ii = 0;
    Difference jj = 0;
    swig::slice_adjust(i, j, step, size, ii, jj);

    if (step > 0) {
      typename Sequence::const_iterator sb = self->begin();
      typename Sequence::const_iterator se = self->begin();
      std::advance(sb,ii);
      std::advance(se,jj);
      if (step == 1) {
        return new Sequence(sb, se);
      } else {
        Sequence *sequence = new Sequence();
        swig::traits_reserve<Sequence>::reserve(*sequence, (jj - ii + step - 1) / step);
        typename Sequence::const_iterator it = sb;
        while (it!=se) {
          sequence->push_back(*it);
          for (Py_ssize_t c=0; c<step && it!=se; ++c)
            it++;
        }
        return sequence;
      } 
    } else {
      Sequence *sequence = new Sequence();
      swig::traits_reserve<Sequence>::reserve(*sequence, (ii - jj - step - 1) / -step);
      typename Sequence::const_reverse_iterator sb = self->rbegin();
      typename Sequence::const_reverse_iterator se = self->rbegin();
      std::advance(sb,size-ii-1);
      std::advance(se,size-jj-1);
      typename Sequence::const_reverse_iterator it = sb;
      while (it!=se) {
        sequence->push_back(*it);
        for (Py_ssize_t c=0; c<-step && it!=se; ++c)
          it++;
      }
      return sequence;
    }
  }

  template <class Sequence, class Difference, class InputSeq>
  inline void
  setslice(Sequence* self, Difference i, Difference j, Py_ssize_t step, const InputSeq& is = InputSeq()) {
    typename Sequence::size_type size = self->size();
    Difference ii = 0;
    Difference jj = 0;
    swig::slice_adjust(i, j, step, size, ii, jj, true);
    if (step > 0) {
      if (step == 1) {
        size_t ssize = jj - ii;
        if (ssize <= is.size()) {
          // expanding/staying the same size
          swig::traits_reserve<Sequence>::reserve(*self, self->size() - ssize + is.size());
          typename Sequence::iterator sb = self->begin();
          typename InputSeq::const_iterator isit = is.begin();
          std::advance(sb,ii);
          std::advance(isit, jj - ii);
          self->insert(std::copy(is.begin(), isit, sb), isit, is.end());
        } else {
          // shrinking
          typename Sequence::iterator sb = self->begin();
          typename Sequence::iterator se = self->begin();
          std::advance(sb,ii);
          std::advance(se,jj);
          self->erase(sb,se);
          sb = self->begin();
          std::advance(sb,ii);
          self->insert(sb, is.begin(), is.end());
        }
      } else {
        size_t replacecount = (jj - ii + step - 1) / step;
        if (is.size() != replacecount) {
          char msg[1024];
          PyOS_snprintf(msg, sizeof(msg), "attempt to assign sequence of size %lu to extended slice of size %lu", (unsigned long)is.size(), (unsigned long)replacecount);
          throw std::invalid_argument(msg);
        }
        typename Sequence::const_iterator isit = is.begin();
        typename Sequence::iterator it = self->begin();
        std::advance(it,ii);
        for (size_t rc=0; rc<replacecount && it != self->end(); ++rc) {
          *it++ = *isit++;
          for (Py_ssize_t c=0; c<(step-1) && it != self->end(); ++c)
            it++;
        }
      }
    } else {
      size_t replacecount = (ii - jj - step - 1) / -step;
      if (is.size() != replacecount) {
        char msg[1024];
        PyOS_snprintf(msg, sizeof(msg), "attempt to assign sequence of size %lu to extended slice of size %lu", (unsigned long)is.size(), (unsigned long)replacecount);
        throw std::invalid_argument(msg);
      }
      typename Sequence::const_iterator isit = is.begin();
      typename Sequence::reverse_iterator it = self->rbegin();
      std::advance(it,size-ii-1);
      for (size_t rc=0; rc<replacecount && it != self->rend(); ++rc) {
        *it++ = *isit++;
        for (Py_ssize_t c=0; c<(-step-1) && it != self->rend(); ++c)
          it++;
      }
    }
  }

  template <class Sequence, class Difference>
  inline void
  delslice(Sequence* self, Difference i, Difference j, Py_ssize_t step) {
    typename Sequence::size_type size = self->size();
    Difference ii = 0;
    Difference jj = 0;
    swig::slice_adjust(i, j, step, size, ii, jj, true);
    if (step > 0) {
      typename Sequence::iterator sb = self->begin();
      std::advance(sb,ii);
      if (step == 1) {
        typename Sequence::iterator se = self->begin();
        std::advance(se,jj);
        self->erase(sb,se);
      } else {
        typename Sequence::iterator it = sb;
        size_t delcount = (jj - ii + step - 1) / step;
        while (delcount) {
          it = self->erase(it);
          for (Py_ssize_t c=0; c<(step-1) && it != self->end(); ++c)
            it++;
          delcount--;
        }
      }
    } else {
      typename Sequence::reverse_iterator sb = self->rbegin();
      std::advance(sb,size-ii-1);
      typename Sequence::reverse_iterator it = sb;
      size_t delcount = (ii - jj - step - 1) / -step;
      while (delcount) {
        it = typename Sequence::reverse_iterator(self->erase((++it).base()));
        for (Py_ssize_t c=0; c<(-step-1) && it != self->rend(); ++c)
          it++;
        delcount--;
      }
    }
  }
}
}

%define %swig_sequence_iterator(Sequence...)
  %swig_sequence_iterator_with_making_function(swig::make_output_iterator,Sequence...)
%enddef

%define %swig_sequence_forward_iterator(Sequence...)
  %swig_sequence_iterator_with_making_function(swig::make_output_forward_iterator,Sequence...)
%enddef

%define %swig_sequence_iterator_with_making_function(Make_output_iterator,Sequence...)
#if defined(SWIG_EXPORT_ITERATOR_METHODS)
  class iterator;
  class reverse_iterator;
  class const_iterator;
  class const_reverse_iterator;

  %typemap(out,noblock=1,fragment="SwigPyIterator_T")
    iterator, reverse_iterator, const_iterator, const_reverse_iterator {
    $result = SWIG_NewPointerObj(Make_output_iterator(%static_cast($1,const $type &)),
				 swig::SwigPyIterator::descriptor(),SWIG_POINTER_OWN);
  }
  %typemap(out,noblock=1,fragment="SwigPyIterator_T")
    std::pair<iterator, iterator>, std::pair<const_iterator, const_iterator> {
    $result = PyTuple_New(2);
    PyTuple_SetItem($result,0,SWIG_NewPointerObj(Make_output_iterator(%static_cast($1,const $type &).first),
						 swig::SwigPyIterator::descriptor(),SWIG_POINTER_OWN));
    PyTuple_SetItem($result,1,SWIG_NewPointerObj(Make_output_iterator(%static_cast($1,const $type &).second),
						 swig::SwigPyIterator::descriptor(),SWIG_POINTER_OWN));    
  }

  %fragment("SwigPyPairBoolOutputIterator","header",fragment=SWIG_From_frag(bool),fragment="SwigPyIterator_T") {}

  %typemap(out,noblock=1,fragment="SwigPyPairBoolOutputIterator")
    std::pair<iterator, bool>, std::pair<const_iterator, bool> {
    $result = PyTuple_New(2);
    PyTuple_SetItem($result,0,SWIG_NewPointerObj(Make_output_iterator(%static_cast($1,const $type &).first),
					       swig::SwigPyIterator::descriptor(),SWIG_POINTER_OWN));    
    PyTuple_SetItem($result,1,SWIG_From(bool)(%static_cast($1,const $type &).second));
  }

  %typemap(in,noblock=1,fragment="SwigPyIterator_T")
    iterator(swig::SwigPyIterator *iter = 0, int res),
    reverse_iterator(swig::SwigPyIterator *iter = 0, int res),
    const_iterator(swig::SwigPyIterator *iter = 0, int res),
    const_reverse_iterator(swig::SwigPyIterator *iter = 0, int res) {
    res = SWIG_ConvertPtr($input, %as_voidptrptr(&iter), swig::SwigPyIterator::descriptor(), 0);
    if (!SWIG_IsOK(res) || !iter) {
      %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
    } else {
      swig::SwigPyIterator_T<$type > *iter_t = dynamic_cast<swig::SwigPyIterator_T<$type > *>(iter);
      if (iter_t) {
	$1 = iter_t->get_current();
      } else {
	%argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
      }
    }
  }

  %typecheck(%checkcode(ITERATOR),noblock=1,fragment="SwigPyIterator_T")
    iterator, reverse_iterator, const_iterator, const_reverse_iterator {
    swig::SwigPyIterator *iter = 0;
    int res = SWIG_ConvertPtr($input, %as_voidptrptr(&iter), swig::SwigPyIterator::descriptor(), 0);
    $1 = (SWIG_IsOK(res) && iter && (dynamic_cast<swig::SwigPyIterator_T<$type > *>(iter) != 0));
  }

  %fragment("SwigPyIterator_T");

  %newobject iterator(PyObject **PYTHON_SELF);
  %extend  {
    swig::SwigPyIterator* iterator(PyObject **PYTHON_SELF) {
      return Make_output_iterator(self->begin(), self->begin(), self->end(), *PYTHON_SELF);
    }

#if defined(SWIGPYTHON_BUILTIN)
  %feature("python:slot", "tp_iter", functype="getiterfunc") iterator;
#else
  %pythoncode %{def __iter__(self):
    return self.iterator()%}
#endif
  }

#endif //SWIG_EXPORT_ITERATOR_METHODS
%enddef


/**** The python container methods  ****/

%define %swig_container_methods(Container...)

/* deprecated in Python 2 */
#if 1
  %newobject __getslice__;
#endif
  %newobject __getitem__(SWIGPY_SLICEOBJECT *slice);

#if defined(SWIGPYTHON_BUILTIN)
  %feature("python:slot", "nb_nonzero", functype="inquiry") __nonzero__;
  %feature("python:slot", "sq_length", functype="lenfunc") __len__;
#endif // SWIGPYTHON_BUILTIN

  %extend {
    bool __nonzero__() const {
      return !(self->empty());
    }

    /* Alias for Python 3 compatibility */
    bool __bool__() const {
      return !(self->empty());
    }

    size_type __len__() const {
      return self->size();
    }

    // Although __getitem__, front, back actually use a const value_type& return type, the typemaps below
    // use non-const so that they can be easily overridden by users if necessary.
    %typemap(ret, fragment="reference_container_owner", noblock=1) value_type& __getitem__, value_type& front, value_type& back {
      if (!swig::container_owner<swig::traits<$*1_ltype>::category>::back_reference($result, $self) && PyErr_Occurred()) {
        SWIG_fail;
      }
    }
  }
%enddef



%define %swig_sequence_methods_common(Sequence...)
  %swig_sequence_iterator(%arg(Sequence))
  %swig_container_methods(%arg(Sequence))

  %fragment("SwigPySequence_Base");

#if defined(SWIGPYTHON_BUILTIN)
  //%feature("python:slot", "sq_item", functype="ssizeargfunc") __getitem__;
  //%feature("python:slot", "sq_slice", functype="ssizessizeargfunc") __getslice__;
  //%feature("python:slot", "sq_ass_item", functype="ssizeobjargproc") __setitem__;
  //%feature("python:slot", "sq_ass_slice", functype="ssizessizeobjargproc") __setslice__;
  %feature("python:slot", "mp_subscript", functype="binaryfunc") __getitem__;
  %feature("python:slot", "mp_ass_subscript", functype="objobjargproc") __setitem__;
#endif // SWIGPYTHON_BUILTIN

  %extend {
    /* typemap for slice object support */
    %typemap(in) SWIGPY_SLICEOBJECT* {
      if (!PySlice_Check($input)) {
        %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
      }
      $1 = (SWIGPY_SLICEOBJECT *) $input;
    }
    %typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) SWIGPY_SLICEOBJECT* {
      $1 = PySlice_Check($input);
    }

/* deprecated in Python 2 */
#if 1
    Sequence* __getslice__(difference_type i, difference_type j) throw (std::out_of_range, std::invalid_argument) {
      return swig::getslice(self, i, j, 1);
    }

    void __setslice__(difference_type i, difference_type j) throw (std::out_of_range, std::invalid_argument) {
      swig::setslice(self, i, j, 1, Sequence());
    }

    void __setslice__(difference_type i, difference_type j, const Sequence& v) throw (std::out_of_range, std::invalid_argument) {
      swig::setslice(self, i, j, 1, v);
    }

    void __delslice__(difference_type i, difference_type j) throw (std::out_of_range, std::invalid_argument) {
      swig::delslice(self, i, j, 1);
    }
#endif

    void __delitem__(difference_type i) throw (std::out_of_range, std::invalid_argument) {
      swig::erase(self, swig::getpos(self, i));
    }

    /* Overloaded methods for Python 3 compatibility 
     * (Also useful in Python 2.x)
     */
    Sequence* __getitem__(SWIGPY_SLICEOBJECT *slice) throw (std::out_of_range, std::invalid_argument) {
      Py_ssize_t i, j, step;
      if( !PySlice_Check(slice) ) {
        SWIG_Error(SWIG_TypeError, "Slice object expected.");
        return NULL;
      }
      PySlice_GetIndices(slice, (Py_ssize_t)self->size(), &i, &j, &step);
      Sequence::difference_type id = i;
      Sequence::difference_type jd = j;
      return swig::getslice(self, id, jd, step);
    }

    void __setitem__(SWIGPY_SLICEOBJECT *slice, const Sequence& v) throw (std::out_of_range, std::invalid_argument) {
      Py_ssize_t i, j, step;
      if( !PySlice_Check(slice) ) {
        SWIG_Error(SWIG_TypeError, "Slice object expected.");
        return;
      }
      PySlice_GetIndices(slice, (Py_ssize_t)self->size(), &i, &j, &step);
      Sequence::difference_type id = i;
      Sequence::difference_type jd = j;
      swig::setslice(self, id, jd, step, v);
    }

    void __setitem__(SWIGPY_SLICEOBJECT *slice) throw (std::out_of_range, std::invalid_argument) {
      Py_ssize_t i, j, step;
      if( !PySlice_Check(slice) ) {
        SWIG_Error(SWIG_TypeError, "Slice object expected.");
        return;
      }
      PySlice_GetIndices(slice, (Py_ssize_t)self->size(), &i, &j, &step);
      Sequence::difference_type id = i;
      Sequence::difference_type jd = j;
      swig::delslice(self, id, jd, step);
    }

    void __delitem__(SWIGPY_SLICEOBJECT *slice) throw (std::out_of_range, std::invalid_argument) {
      Py_ssize_t i, j, step;
      if( !PySlice_Check(slice) ) {
        SWIG_Error(SWIG_TypeError, "Slice object expected.");
        return;
      }
      PySlice_GetIndices(slice, (Py_ssize_t)self->size(), &i, &j, &step);
      Sequence::difference_type id = i;
      Sequence::difference_type jd = j;
      swig::delslice(self, id, jd, step);
    }

  }
%enddef

%define %swig_sequence_methods_non_resizable(Sequence...)
  %swig_sequence_methods_common(%arg(Sequence))
  %extend {
    const value_type& __getitem__(difference_type i) const throw (std::out_of_range) {
      return *(swig::cgetpos(self, i));
    }

    void __setitem__(difference_type i, const value_type& x) throw (std::out_of_range) {
      *(swig::getpos(self,i)) = x;
    }

#if defined(SWIGPYTHON_BUILTIN)
    // This will be called through the mp_ass_subscript slot to delete an entry.
    void __setitem__(difference_type i) throw (std::out_of_range, std::invalid_argument) {
      swig::erase(self, swig::getpos(self, i));
    }
#endif

  }
%enddef

%define %swig_sequence_methods(Sequence...)
  %swig_sequence_methods_non_resizable(%arg(Sequence))
  %extend {
    value_type pop() throw (std::out_of_range) {
      if (self->size() == 0)
	throw std::out_of_range("pop from empty container");
      Sequence::value_type x = self->back();
      self->pop_back();
      return x;
    }

    void append(const value_type& x) {
      self->push_back(x);
    }
  }
%enddef

%define %swig_sequence_methods_non_resizable_val(Sequence...)
  %swig_sequence_methods_common(%arg(Sequence))
  %extend {
    value_type __getitem__(difference_type i) throw (std::out_of_range) {
      return *(swig::cgetpos(self, i));
    }

    void __setitem__(difference_type i, value_type x) throw (std::out_of_range) {
      *(swig::getpos(self,i)) = x;
    }

#if defined(SWIGPYTHON_BUILTIN)
    // This will be called through the mp_ass_subscript slot to delete an entry.
    void __setitem__(difference_type i) throw (std::out_of_range, std::invalid_argument) {
      swig::erase(self, swig::getpos(self, i));
    }
#endif
  }
%enddef

%define %swig_sequence_methods_val(Sequence...)
  %swig_sequence_methods_non_resizable_val(%arg(Sequence))
  %extend {
    value_type pop() throw (std::out_of_range) {
      if (self->size() == 0)
	throw std::out_of_range("pop from empty container");
      Sequence::value_type x = self->back();
      self->pop_back();
      return x;
    }

    void append(value_type x) {
      self->push_back(x);
    }
  }
%enddef



//
// Common fragments
//

%fragment("StdSequenceTraits","header",
	  fragment="StdTraits",
	  fragment="SwigPySequence_Base")
{
namespace swig {
  template <class Seq, class T = typename Seq::value_type >
  struct IteratorProtocol {
    static void assign(PyObject *obj, Seq *seq) {
      SwigVar_PyObject iter = PyObject_GetIter(obj);
      if (iter) {
        SwigVar_PyObject item = PyIter_Next(iter);
        while (item) {
          seq->insert(seq->end(), swig::as<T>(item));
          item = PyIter_Next(iter);
        }
      }
    }

    static bool check(PyObject *obj) {
      bool ret = false;
      SwigVar_PyObject iter = PyObject_GetIter(obj);
      if (iter) {
        SwigVar_PyObject item = PyIter_Next(iter);
        ret = true;
        while (item) {
          ret = swig::check<T>(item);
          item = ret ? PyIter_Next(iter) : 0;
        }
      }
      return ret;
    }
  };

  template <class Seq, class T = typename Seq::value_type >
  struct traits_asptr_stdseq {
    typedef Seq sequence;
    typedef T value_type;

    static bool is_iterable(PyObject *obj) {
      SwigVar_PyObject iter = PyObject_GetIter(obj);
      PyErr_Clear();
      return iter != 0;
    }

    static int asptr(PyObject *obj, sequence **seq) {
      int ret = SWIG_ERROR;
      if (obj == Py_None || SWIG_Python_GetSwigThis(obj)) {
	sequence *p;
	swig_type_info *descriptor = swig::type_info<sequence>();
	if (descriptor && SWIG_IsOK(::SWIG_ConvertPtr(obj, (void **)&p, descriptor, 0))) {
	  if (seq) *seq = p;
	  return SWIG_OLDOBJ;
	}
      } else if (is_iterable(obj)) {
	try {
	  if (seq) {
	    *seq = new sequence();
            IteratorProtocol<Seq, T>::assign(obj, *seq);
            if (!PyErr_Occurred())
              return SWIG_NEWOBJ;
	  } else {
	    return IteratorProtocol<Seq, T>::check(obj) ? SWIG_OK : SWIG_ERROR;
	  }
	} catch (std::exception& e) {
          if (seq && !PyErr_Occurred())
            PyErr_SetString(PyExc_TypeError, e.what());
	}
        if (seq)
          delete *seq;
	return SWIG_ERROR;
      }
      return ret;
    }
  };

  template <class Seq, class T = typename Seq::value_type >
  struct traits_from_stdseq {
    typedef Seq sequence;
    typedef T value_type;
    typedef typename Seq::size_type size_type;
    typedef typename sequence::const_iterator const_iterator;

    static PyObject *from(const sequence& seq) {
%#ifdef SWIG_PYTHON_EXTRA_NATIVE_CONTAINERS
      swig_type_info *desc = swig::type_info<sequence>();
      if (desc && desc->clientdata) {
	return SWIG_InternalNewPointerObj(new sequence(seq), desc, SWIG_POINTER_OWN);
      }
%#endif
      size_type size = seq.size();
      if (size <= (size_type)PY_SSIZE_T_MAX) {
	PyObject *obj = PyTuple_New((Py_ssize_t)size);
	Py_ssize_t i = 0;
	for (const_iterator it = seq.begin(); it != seq.end(); ++it, ++i) {
	  PyTuple_SetItem(obj,i,swig::from<value_type>(*it));
	}
	return obj;
      } else {
	PyErr_SetString(PyExc_OverflowError,"sequence size not valid in python");
	return NULL;
      }
    }
  };
}
}

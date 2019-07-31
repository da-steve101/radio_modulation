#include <Python.h>
#include "tw_vgg10.h"

// doc_str of length 77, allow 149 + '/0' so 72
char * doc_str = "A Python module that computes a low precision VGG network using CSE on model %.72s";
char new_doc[150];

static PyObject* compute(PyObject *self, PyObject *args) {
  PyObject * in_list;
  if (!PyArg_ParseTuple(args, "O", &in_list)) {
    return NULL;
  }
  if ( !PyList_Check(in_list) )
    Py_RETURN_NONE;
  Py_ssize_t len = PyList_Size( in_list );
  short * img = (short*)PyMem_Malloc(sizeof(short)*len);
  int i;
  for ( i = 0; i < len; i++ ) {
    PyObject * in_num = PyList_GetItem( in_list, i );
    img[i] = (short)PyLong_AsLong( in_num );
  }
  short * out_img = compute_network( img );
  PyObject * out_list = PyList_New(0);
  for ( i = 0; i < NO_CLASSES; i++ ) {
    PyObject * num = Py_BuildValue( "h", (short)(out_img[i]) );
    PyList_Append( out_list, num );
  }
  return out_list;
}

static PyMethodDef pyvgg_methods[] = {
  {
    "compute", compute, METH_VARARGS,
    "Take in a signal of 1024 I/Q samples in the form [ I0, Q0, I1, Q1, ..., I1023, Q1023 ]"
  },
  {NULL, NULL, 0, NULL}
};

static struct PyModuleDef pyvgg_definition = {
  PyModuleDef_HEAD_INIT,
  "pyvgg",
  (char*)new_doc,
  -1,
  pyvgg_methods
};

PyMODINIT_FUNC PyInit_pyvgg(void) {
  Py_Initialize();
  allocate_network( D3_PREC );
  sprintf( new_doc, doc_str, MODEL_DIR );
  return PyModule_Create(&pyvgg_definition);
}

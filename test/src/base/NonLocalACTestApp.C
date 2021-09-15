//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "NonLocalACTestApp.h"
#include "NonLocalACApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"
#include "ModulesApp.h"

InputParameters
NonLocalACTestApp::validParams()
{
  InputParameters params = NonLocalACApp::validParams();
  return params;
}

NonLocalACTestApp::NonLocalACTestApp(InputParameters parameters) : MooseApp(parameters)
{
  NonLocalACTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

NonLocalACTestApp::~NonLocalACTestApp() {}

void
NonLocalACTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  NonLocalACApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"NonLocalACTestApp"});
    Registry::registerActionsTo(af, {"NonLocalACTestApp"});
  }
}

void
NonLocalACTestApp::registerApps()
{
  registerApp(NonLocalACApp);
  registerApp(NonLocalACTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
NonLocalACTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  NonLocalACTestApp::registerAll(f, af, s);
}
extern "C" void
NonLocalACTestApp__registerApps()
{
  NonLocalACTestApp::registerApps();
}

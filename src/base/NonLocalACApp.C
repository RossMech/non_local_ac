#include "NonLocalACApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
NonLocalACApp::validParams()
{
  InputParameters params = MooseApp::validParams();

  // Do not use legacy material output, i.e., output properties on INITIAL as well as TIMESTEP_END
  params.set<bool>("use_legacy_material_output") = false;

  return params;
}

NonLocalACApp::NonLocalACApp(InputParameters parameters) : MooseApp(parameters)
{
  NonLocalACApp::registerAll(_factory, _action_factory, _syntax);
}

NonLocalACApp::~NonLocalACApp() {}

void
NonLocalACApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  ModulesApp::registerAll(f, af, syntax);
  Registry::registerObjectsTo(f, {"NonLocalACApp"});
  Registry::registerActionsTo(af, {"NonLocalACApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
NonLocalACApp::registerApps()
{
  registerApp(NonLocalACApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
NonLocalACApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  NonLocalACApp::registerAll(f, af, s);
}
extern "C" void
NonLocalACApp__registerApps()
{
  NonLocalACApp::registerApps();
}

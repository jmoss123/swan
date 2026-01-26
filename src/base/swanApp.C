#include "swanApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
swanApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

swanApp::swanApp(const InputParameters & parameters) : MooseApp(parameters)
{
  swanApp::registerAll(_factory, _action_factory, _syntax);
}

swanApp::~swanApp() {}

void
swanApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  ModulesApp::registerAllObjects<swanApp>(f, af, syntax);
  Registry::registerObjectsTo(f, {"swanApp"});
  Registry::registerActionsTo(af, {"swanApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
swanApp::registerApps()
{
  registerApp(swanApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
swanApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  swanApp::registerAll(f, af, s);
}
extern "C" void
swanApp__registerApps()
{
  swanApp::registerApps();
}

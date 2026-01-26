//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "swanTestApp.h"
#include "swanApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
swanTestApp::validParams()
{
  InputParameters params = swanApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

swanTestApp::swanTestApp(const InputParameters & parameters) : MooseApp(parameters)
{
  swanTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

swanTestApp::~swanTestApp() {}

void
swanTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  swanApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"swanTestApp"});
    Registry::registerActionsTo(af, {"swanTestApp"});
  }
}

void
swanTestApp::registerApps()
{
  registerApp(swanApp);
  registerApp(swanTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
swanTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  swanTestApp::registerAll(f, af, s);
}
extern "C" void
swanTestApp__registerApps()
{
  swanTestApp::registerApps();
}

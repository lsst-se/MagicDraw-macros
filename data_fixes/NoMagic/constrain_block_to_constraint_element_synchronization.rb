##
#This macro was created to apply the ConstraintBlock stereotype to all ConstraintElements and vice versa.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper

$project = Application.getInstance().getProject()

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML')
$lsstProfile = StereotypesHelper.getProfile($project,'LSST Profile')

$sysmlConstraintBlockStereotype = StereotypesHelper.getStereotype($project,'ConstraintBlock',$sysmlProfile)
$sysmlConstraintElementStereotype = StereotypesHelper.getStereotype($project,'ConstraintElement',$lsstProfile)

def recursiveEASearch(element)
	if(StereotypesHelper.hasStereotype(element,$sysmlConstraintBlockStereotype) or StereotypesHelper.hasStereotype(element,$sysmlConstraintElementStereotype))
		StereotypesHelper.addStereotype(element,$sysmlConstraintBlockStereotype)
		StereotypesHelper.addStereotype(element,$sysmlConstraintElementStereotype)
	end
	for child in element.getOwnedElement()
    	recursiveEASearch(child)
	end
end

begin
	SessionManager.getInstance().createSession("Fix ConstraintBlocks") 

	recursiveEASearch($project.getPrimaryModel())
ensure
	SessionManager.getInstance().closeSession()
end
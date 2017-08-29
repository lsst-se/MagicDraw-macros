##
#This macro was created to add the SysML Requirement stereotype to all DM_Req_Priority elements.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper

$project = Application.getInstance().getProject();

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');
$lsstProfile = StereotypesHelper.getProfile($project,'LSST Profile');

$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$lsstDM_Req_PriorityStereotype = StereotypesHelper.getStereotype($project,'DM_Req_Priority',$lsstProfile);

def recursiveEASearch(element)
	if(StereotypesHelper.hasStereotype(element,$lsstDM_Req_PriorityStereotype))
		StereotypesHelper.addStereotype(element,$sysmlRequirementStereotype);
	end
	for child in element.getOwnedElement()
    	recursiveEASearch(child);
	end
end

begin
	SessionManager.getInstance().createSession("Fix Requirements"); 

	recursiveEASearch($project.getPrimaryModel());
ensure
	SessionManager.getInstance().closeSession();
end
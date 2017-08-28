##
#This macro was created to take the HTML from the documentation field, parse it, and then place the Specification section in the Text field and the Discussion in the Documentation field.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject();

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');
                                                                                  
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$sysmlInterfaceRequirementStereotype = StereotypesHelper.getStereotype($project,'interfaceRequirement',$sysmlProfile);

def recursiveEASearch(element)
	if(StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype) or StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype))
		
		comment = ModelHelper.getComment(element);
		if(comment.index('<b>Specification') == nil)
			ModelHelper.setComment(element,comment);
			StereotypesHelper.setStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text','');
		elsif(comment.index('<b>Discussion') == nil)
			StereotypesHelper.setStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text',comment);
			ModelHelper.setComment(element,'');
		else
			StereotypesHelper.setStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text','<html><pre>' + comment[comment.index('<b>Specification')..(comment.index('<b>Discussion')-1)].strip + '</pre></html>');
			ModelHelper.setComment(element,comment.gsub(comment[comment.index('<b>Specification')..(comment.index('<b>Discussion')-1)],''));
		end
	end
	for child in element.getOwnedElement()
    	recursiveEASearch(child);
	end
end

begin
	SessionManager.getInstance().createSession("Fix Reqs"); 
	
	recursiveEASearch($project.getPrimaryModel());
ensure
	SessionManager.getInstance().closeSession();
end
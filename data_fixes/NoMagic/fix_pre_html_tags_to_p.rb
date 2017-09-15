##
#This macro was created to change the <pre> tags to <p> tages in the documentation and text fields.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper

$project = Application.getInstance().getProject()

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML')
                                                                                  
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile)
$sysmlInterfaceRequirementStereotype = StereotypesHelper.getStereotype($project,'interfaceRequirement',$sysmlProfile)

def recursiveEASearch(element)
	
	comment = ModelHelper.getComment(element)
	comment = comment.gsub('<pre>','<p>').gsub('</pre>','</p>')
	ModelHelper.setComment(element,comment)

	if(StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) and !StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text').isEmpty())
		comment = StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text').get(0)
		comment = comment.gsub('<pre>','<p>').gsub('</pre>','</p>')
		StereotypesHelper.setStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text',comment)
	elsif(StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype) and !StereotypesHelper.getStereotypePropertyValue(element,$sysmlInterfaceRequirementStereotype,'Text').isEmpty())
		comment = StereotypesHelper.getStereotypePropertyValue(element,$sysmlInterfaceRequirementStereotype,'Text').get(0)
		comment = comment.gsub('<pre>','<p>').gsub('</pre>','</p>')
		StereotypesHelper.setStereotypePropertyValue(element,$sysmlInterfaceRequirementStereotype,'Text',comment)
	end

	for child in element.getOwnedElement()
    	recursiveEASearch(child)
	end
end

begin
	SessionManager.getInstance().createSession("Fix HTML") 
	
	recursiveEASearch($project.getPrimaryModel())
ensure
	SessionManager.getInstance().closeSession()
end
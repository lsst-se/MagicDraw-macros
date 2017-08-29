##
#This macro was created to fix ConstraintBlocks that were missing the refines relations.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject();
$elementsFactory = $project.getElementsFactory();

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');

$sysmlConstraintBlockStereotype = StereotypesHelper.getStereotype($project,'ConstraintBlock',$sysmlProfile);
$sysmlRefineStereotype = StereotypesHelper.getStereotype($project,'Refine',$sysmlProfile);

$refinesLocation = ModelHelper.findElementWithPath('Requirements::Refines Relations');

$elementsToRemove = java.util.ArrayList.new;

def recursiveEASearch(element)
	if(StereotypesHelper.hasStereotype(element,$sysmlConstraintBlockStereotype))
		if(element.get_relationshipOfRelatedElement().size() == 0)
			refines = $elementsFactory.createAbstractionInstance();
			StereotypesHelper.addStereotype(refines,$sysmlRefineStereotype);
			ModelHelper.setSupplierElement(refines,element.getOwner());
			ModelHelper.setClientElement(refines,element);
			refines.setOwner($refinesLocation);
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
##
#This macro takes requirement properties, creates ConstraintBlocks, and then creates Refines relations.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject();
$elementsFactory = $project.getElementsFactory();

$eaProfile = StereotypesHelper.getProfile($project,'EA Profile');
$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');
$lsstProfile = StereotypesHelper.getProfile($project,'LSST Profile');
                                                                                  
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$sysmlConstraintBlockStereotype = StereotypesHelper.getStereotype($project,'ConstraintBlock',$sysmlProfile);
$sysmlRefineStereotype = StereotypesHelper.getStereotype($project,'Refine',$sysmlProfile);

$sysmlConstraintElementStereotype = StereotypesHelper.getStereotype($project,'ConstraintElement',$lsstProfile);

$eaRequirementStereotype = StereotypesHelper.getStereotype($project,'EARequirement',$eaProfile);

$realType = ModelHelper.findElementWithPath('SysML::Libraries::PrimitiveValueTypes::Real');

$elementsToRemove = java.util.ArrayList.new;

def recursiveEASearch(element)
	if(element.getHumanName().include? 'Class System Composition and Constraints :' or element.getHumanName() == 'Class ')
		$elementsToRemove.add(element);
	elsif(element.hasOwnedElement())
		for child in element.getOwnedElement()
			if(StereotypesHelper.hasStereotype(element,$sysmlConstraintElementStereotype) and child.getHumanType() == 'Property' and (StereotypesHelper.hasStereotype(element.getOwner(),$eaRequirementStereotype) or StereotypesHelper.hasStereotype(element.getOwner(),$sysmlRequirementStereotype)))
				$elementsToRemove.add(element);
				constraintBlock = $elementsFactory.createClassInstance();
				constraintBlock.setName(child.getName());
				StereotypesHelper.addStereotype(constraintBlock,$sysmlConstraintBlockStereotype);

				#This section parses the property and creates the ConstraintBlocks
				constraintProperty = $elementsFactory.createConstraintInstance();
				if(child.getDefaultValue() != nil and child.getDefaultValue().respond_to?(:getValue))
					constraintSpec = $elementsFactory.createOpaqueExpressionInstance();
					constraintSpec.getBody().add(child.getName() + ' = ' + child.getDefaultValue().getValue().to_s);
					constraintProperty.setSpecification(constraintSpec);
					constraintSpec.setOwner(constraintProperty);
				end
				constraintProperty.setOwner(constraintBlock);
				constraintBlock.get_constraintOfConstrainedElement().add(constraintProperty);
				constraintBlock.setOwner(element.getOwner());
				ModelHelper.setComment(constraintBlock,ModelHelper.getComment(child));

				##This section creates the refines relation
				refines = $elementsFactory.createAbstractionInstance();
				StereotypesHelper.addStereotype(refines,$sysmlRefineStereotype);
				ModelHelper.setSupplierElement(refines,element.getOwner());
				ModelHelper.setClientElement(refines,constraintBlock);
				refines.setOwner(element.getOwner());
			end
		end
	end
	for child in element.getOwnedElement()
    	recursiveEASearch(child);
	end
end

begin
	SessionManager.getInstance().createSession("Req_Macro"); 
	recursiveEASearch($project.getPrimaryModel());
	ModelHelper.dispose($elementsToRemove);
ensure
	SessionManager.getInstance().closeSession();
end
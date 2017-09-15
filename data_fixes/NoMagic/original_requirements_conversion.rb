##
#This was the original requirements macro that converted the requirements from EA.
#This macro takes Requirements, copies the documentation to the text field, creates constraint blocks, and creates the refines relations.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper

$project = Application.getInstance().getProject()
$elementsFactory = $project.getElementsFactory()

$eaProfile = StereotypesHelper.getProfile($project,'thecustomprofile')
$sysmlProfile = StereotypesHelper.getProfile($project,'SysML')
                                                                                  
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile)
$sysmlConstraintBlockStereotype = StereotypesHelper.getStereotype($project,'ConstraintBlock',$sysmlProfile)
$sysmlRefineStereotype = StereotypesHelper.getStereotype($project,'Refine',$sysmlProfile)

$eaRequirementStereotype = StereotypesHelper.getStereotype($project,'LSSTRequirements',$eaProfile)

$realType = ModelHelper.findElementWithPath('SysML::Libraries::PrimitiveValueTypes::Real')

$elementsToRemove = java.util.ArrayList.new

def recursiveEASearch(element)
	if(StereotypesHelper.hasStereotype(element,$eaRequirementStereotype))

		StereotypesHelper.removeStereotype(element,$eaRequirementStereotype)
		StereotypesHelper.addStereotype(element,$sysmlRequirementStereotype)

		specification = ''
		discussion = ''
		tempValue = ModelHelper.getComment(element).gsub('<[^>]*>','').strip
		tempArray = tempValue.split('Specification:  ')
		if(tempArray.size > 0)
			tempArray = tempArray[0].split('Discussion: ')
			specification = tempArray[0]
			discussion = tempArray[1]
		end
		Application.getInstance().getGUILog().log('Name: ' + element.getName() + ' :: Size: ' + tempArray.size())

		if(!StereotypesHelper.getStereotypePropertyValue(element,$eaRequirementStereotype,'LSSTRequirements').isEmpty())
			StereotypesHelper.setStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id',StereotypesHelper.getStereotypePropertyValue(element,$eaRequirementStereotype,'LSSTRequirements').get(0))
		end

		if(specification != nil)
			StereotypesHelper.setStereotypePropertyValue(element,$sysmlRequirementStereotype,'Text',specification)
		end
		if(discussion != nil)
			ModelHelper.setComment(element,discussion)
		else
			ModelHelper.setComment(element,'')
		end
	elsif(element.getHumanName().include? 'Class System Composition and Constraints :' or element.getHumanName() == 'Class ')
		$elementsToRemove.add(element)
	elsif(element.hasOwnedElement())
		for child in element.getOwnedElement()
			if(element.getHumanType() == 'Class' and child.getHumanType() == 'Property' and (StereotypesHelper.hasStereotype(element.getOwner(),$eaRequirementStereotype) or StereotypesHelper.hasStereotype(element.getOwner(),$sysmlRequirementStereotype)))
				$elementsToRemove.add(element)
				constraintBlock = $elementsFactory.createClassInstance()
				constraintBlock.setName(child.getName())
				StereotypesHelper.addStereotype(constraintBlock,$sysmlConstraintBlockStereotype)

				constraintProperty = $elementsFactory.createConstraintInstance()
				if(child.getDefaultValue() != nil and child.getDefaultValue().respond_to?(:getValue))
					constraintSpec = $elementsFactory.createOpaqueExpressionInstance()
					constraintSpec.getBody().add(child.getName() + ' = ' + child.getDefaultValue().getValue().to_s)
					constraintProperty.setSpecification(constraintSpec)
					constraintSpec.setOwner(constraintProperty)
				end
				constraintProperty.setOwner(constraintBlock)
				constraintBlock.get_constraintOfConstrainedElement().add(constraintProperty)
				constraintBlock.setOwner(element.getOwner())
				ModelHelper.setComment(constraintBlock,ModelHelper.getComment(child))

				refines = $elementsFactory.createAbstractionInstance()
				StereotypesHelper.addStereotype(refines,$sysmlRefineStereotype)
				ModelHelper.setSupplierElement(refines,element.getOwner())
				ModelHelper.setClientElement(refines,constraintBlock)
			end
		end
	end
	for child in element.getOwnedElement()
    	recursiveEASearch(child)
	end
end

recursiveEASearch($project.getPrimaryModel())
ModelHelper.dispose($elementsToRemove)
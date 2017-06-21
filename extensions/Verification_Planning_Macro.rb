require 'java'

##
#The following section is used to initialize the API classes used throughout the macro
##

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper

##
#The following section sets the $project, $elementsFactory, and $root variables
#The $project variable holds all of the project data
#The $elementsFactory variable is used to create new elements
##

$project = Application.getInstance().getProject();
$elementsFactory = $project.getElementsFactory();

##
#The following section finds the profiles and stereotypes used in the macro
##

$lsstProfile = StereotypesHelper.getProfile($project,'LSST Profile');
$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');
                                                                                  
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$sysmlInterfaceRequirementStereotype = StereotypesHelper.getStereotype($project,'interfaceRequirement',$sysmlProfile);

$vpeStereotype = StereotypesHelper.getStereotype($project,'VerificationElement',$lsstProfile);
$documentStereotype = StereotypesHelper.getStereotype($project,'RequirementVerificationOwner',$lsstProfile);
$vpeRelationshipStereotype = StereotypesHelper.getStereotype($project,'substantiate',$lsstProfile);

##
#The following section is a method that recursively loops through the containment tree
#The method will find all requirements with valid Ids and calls the findOrCretaeVPE method to build the VPEs
##

def recursiveTreeTraversal(element)
	if(element.respond_to?(:getName))
		if((StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype)) and !StereotypesHelper.hasStereotype(element,$vpeStereotype) and StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').isEmpty())
			Application.getInstance().getGUILog().log('Missing Requirement Id for: ' + buildQualifiedName(element));
		elsif(StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype))
			if(element != $project.getPrimaryModel())
				enumList = java.util.ArrayList.new;
				parent = element.getOwner();
				while (parent != $project.getPrimaryModel() and enumList.isEmpty())
					if(StereotypesHelper.hasStereotype(parent,$documentStereotype))
						enumList.addAll(StereotypesHelper.getStereotypePropertyValue(parent,$documentStereotype,'owners'));
					end
					parent = parent.getOwner();
				end
				for enum in enumList
					findOrCreateVPE(element,StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').get(0).to_s + '-V-' + enum.getName());
				end
				findOrCreateVPE(element,StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').get(0).to_s + '-V-PSE');
			end
		elsif(StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) and !StereotypesHelper.hasStereotype(element,$vpeStereotype))
			findOrCreateVPE(element,StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').get(0).to_s + '-V');
		end
	end
	for child in element.getOwnedElement()
    	recursiveTreeTraversal(child);
	end
end

##
#This method searches the siblings of the requirement to try and find an existing VPE for that requirement
#If one is found, it will proceed to the next requirement
#If one is not found, it will create it and assign the custom Id
##

def findOrCreateVPE(requirement,targetId)
	for relation in requirement.get_relationshipOfRelatedElement()
		if(StereotypesHelper.hasStereotype(relation,$vpeRelationshipStereotype) and StereotypesHelper.getStereotypePropertyValue(relation.getSource().get(0),$sysmlRequirementStereotype,'Id').get(0) == targetId)
			return;
		end
	end

	newVPE = $elementsFactory.createClassInstance();
	StereotypesHelper.addStereotype(newVPE,$vpeStereotype);
	newVPE.setName(requirement.getName());
	StereotypesHelper.setStereotypePropertyValue(newVPE,$sysmlRequirementStereotype,'Id',targetId);
	newVPE.setOwner(requirement.getOwner());

	newRelation = $elementsFactory.createAbstractionInstance();
	StereotypesHelper.addStereotype(newRelation,$vpeRelationshipStereotype);
	ModelHelper.setClientElement(newRelation,newVPE);
	ModelHelper.setSupplierElement(newRelation,requirement);
	newRelation.setOwner($selectedNode);
end

##
#This method is used to build the fully qualified name of an element
#This is used solely to output to the Notification Window if a requirement is missing an Id
##

def buildQualifiedName(element)
	if element.getOwner() == nil or element.getOwner().getOwner() == nil
		return element.getHumanName()[element.getHumanType().length,element.getHumanName().length-1].strip;
	end

	return buildQualifiedName(element.getOwner()) + '::' + element.getHumanName()[element.getHumanType().length,element.getHumanName().length-1].strip;
end

##
#The following section is the main method of the macro
#The section calls the methods defined above only if the selected package has the $documentStereotype applied
##

begin
	SessionManager.getInstance().createSession("VPE_Macro"); 

	$selectedNode = Application.getInstance().getProject().getBrowser().getContainmentTree().getSelectedNode().getUserObject();

	if(StereotypesHelper.hasStereotype($selectedNode,$documentStereotype))
		recursiveTreeTraversal($selectedNode);
	else
		Application.getInstance().getGUILog().log('Please select a valid requirement package and rerun.');
	end
ensure
	SessionManager.getInstance().closeSession();
end
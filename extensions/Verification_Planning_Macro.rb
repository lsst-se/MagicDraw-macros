require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper

$project = Application.getInstance().getProject();
$elementsFactory = $project.getElementsFactory();

$lsstProfile = StereotypesHelper.getProfile($project,'LSST Profile');
$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');
                                                                                  
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$sysmlInterfaceRequirementStereotype = StereotypesHelper.getStereotype($project,'interfaceRequirement',$sysmlProfile);

$vpeStereotype = StereotypesHelper.getStereotype($project,'VerificationPlanningElement',$lsstProfile);
$documentStereotype = StereotypesHelper.getStereotype($project,'RequirementsDocument',$lsstProfile);
$vpeRelationshipStereotype = StereotypesHelper.getStereotype($project,'VPERelationship',$lsstProfile);

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
						enumList.addAll(StereotypesHelper.getStereotypePropertyValue(parent,$documentStereotype,'subsystems'));
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

def buildQualifiedName(element)
	if element.getOwner() == nil or element.getOwner().getOwner() == nil
		return element.getHumanName()[element.getHumanType().length,element.getHumanName().length-1].strip;
	end

	return buildQualifiedName(element.getOwner()) + '::' + element.getHumanName()[element.getHumanType().length,element.getHumanName().length-1].strip;
end

$selectedNode = Application.getInstance().getProject().getBrowser().getContainmentTree().getSelectedNode().getUserObject();

if(StereotypesHelper.hasStereotype($selectedNode,$documentStereotype))
	recursiveTreeTraversal($selectedNode);
else
	Application.getInstance().getGUILog().log('Please select a Document package and rerun.');
end
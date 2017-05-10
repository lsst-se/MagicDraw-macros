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

$root = $project.getPrimaryModel();

$lastRequirements = java.util.HashMap.new;
$unmarkedRequirements = java.util.ArrayList.new;

def getLatestIds(element)
	if((StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype)) and !StereotypesHelper.hasStereotype(element,$vpeStereotype))
		if(!StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').isEmpty())
			id = StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').get(0);
			pre = parsePrefix(id);
			post = parsePostfix(id);
			if($lastRequirements.get(pre) != nil)
				if($lastRequirements.get(pre) < post)
					$lastRequirements.put(pre,post);
				end
			else
				$lastRequirements.put(pre,post);
			end
		end
	end
	for child in element.getOwnedElement()
    	getLatestIds(child);
	end
end

def findMissingIds(element)
	if((StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype)) and !StereotypesHelper.hasStereotype(element,$vpeStereotype))
		if(StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').isEmpty())
			$unmarkedRequirements.add(element);
		end
	end
	for child in element.getOwnedElement()
    	findMissingIds(child);
	end
end

def parsePrefix(elementId)

	elementId = elementId.strip;
	lastIndex = lastIndexOf(elementId,'-');
	if(lastIndex == -1 or elementId[lastIndex+1,elementId.length-1].to_i == 0)
		return elementId;
	else
		return elementId[0,lastIndex];
	end
end

def parsePostfix(elementId)

	elementId = elementId.strip;
	lastIndex = lastIndexOf(elementId,'-');
	if(lastIndex == -1 or elementId[lastIndex+1,elementId.length-1].to_i == 0)
		return 0;
	else
		return elementId[lastIndex+1,elementId.length-1].to_i;
	end
end

def lastIndexOf(inputString,character)
	i = inputString.length - 1;

	while i>=0
		if(inputString[i] == character)
			return i;
		end
		i = i - 1;
	end

	return -1;
end

def fixId(element,req)
	if(element == $root or (element.getOwner() == $root and StereotypesHelper.getStereotypePropertyValue($root,$sysmlRequirementStereotype,'Id').isEmpty()))
		Application.getInstance().getGUILog().log("Could not find valid prefix for: " + req.getName());
		return;
	elsif(!StereotypesHelper.getStereotypePropertyValue(element.getOwner(),$sysmlRequirementStereotype,'Id').isEmpty())
		localId = StereotypesHelper.getStereotypePropertyValue(element.getOwner(),$sysmlRequirementStereotype,'Id').get(0).strip;
		if(parsePrefix(localId) == localId)
			nextId = $lastRequirements.get(localId) + 1;
			if(nextId<10)
				StereotypesHelper.setStereotypePropertyValue(req,$sysmlRequirementStereotype,'Id',(localId.to_s + '-000' + nextId.to_s));
			elsif(nextId<100)
				StereotypesHelper.setStereotypePropertyValue(req,$sysmlRequirementStereotype,'Id',(localId.to_s + '-00' + nextId.to_s));
			elsif(nextId<1000)
				StereotypesHelper.setStereotypePropertyValue(req,$sysmlRequirementStereotype,'Id',(localId.to_s + '-0' + nextId.to_s));
			else
				StereotypesHelper.setStereotypePropertyValue(req,$sysmlRequirementStereotype,'Id',(localId.to_s + '-' + nextId.to_s));
			end
			$lastRequirements.put(localId,nextId);
		end
	end

	fixId(element.getOwner(),req);
end

$selectedNode = Application.getInstance().getProject().getBrowser().getContainmentTree().getSelectedNode().getUserObject();

getLatestIds($root);
findMissingIds($selectedNode);

for req in $unmarkedRequirements
	fixId(req,req);
end
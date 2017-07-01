require 'java'

##
#The following section is used to initialize the API classes used throughout the macro
##

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

##
#The following section sets the $project, $elementsFactory, and $root variables
#The $project variable holds all of the project data
#The $elementsFactory variable is used to create new elements
#The $root variable is set to the root package in the project
##

$project = Application.getInstance().getProject();
$elementsFactory = $project.getElementsFactory();
$root = $project.getPrimaryModel();

##
#The following section finds the profiles and stereotypes used in the macro
##

$lsstProfile = StereotypesHelper.getProfile($project,'LSST Profile');
$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');

$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$sysmlInterfaceRequirementStereotype = StereotypesHelper.getStereotype($project,'interfaceRequirement',$sysmlProfile);
$lsstPriortizedRequirementStereotype = StereotypesHelper.getStereotype($project,'DM_Req_Priority',$lsstProfile);

$vpeStereotype = StereotypesHelper.getStereotype($project,'VerificationElement',$lsstProfile);
$uniqueIDStubHolderStereotype = StereotypesHelper.getStereotype($project,'UniqueIDStubHolder',$lsstProfile);

##
#The following section creates an empty HashMap to maintain the last IDs for each ID stub and an ArrayList to hold all requirements without IDs
##

$lastRequirements = java.util.HashMap.new;
$unmarkedRequirements = java.util.ArrayList.new;

##
#The following section is a method that recursively loops through the containment tree
#The method will find the ID of a requirement, find the ID stub, check if the ID is larger than the current highest ID with that stub, and if so, update the HashMap
##

def getLatestIds(element)
	if((StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype) or StereotypesHelper.hasStereotype(element,$lsstPriortizedRequirementStereotype)) and !StereotypesHelper.hasStereotype(element,$vpeStereotype))
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

##
#The following section recursively loops through the selected package and places all requirements without IDs into the ArrayList
##

def findMissingIds(element)
	if((StereotypesHelper.hasStereotype(element,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(element,$sysmlInterfaceRequirementStereotype)) and !StereotypesHelper.hasStereotype(element,$vpeStereotype))
		if(StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').isEmpty() or StereotypesHelper.getStereotypePropertyValue(element,$sysmlRequirementStereotype,'Id').get(0) == '')
			Application.getInstance().getGUILog().log("Unallocated:" + element.getName());
			$unmarkedRequirements.add(element);
		end
	end
	for child in element.getOwnedElement()
    	findMissingIds(child);
	end
end

##
#The following section is used to parse the requirement stub from the IDs
##

def parsePrefix(elementId)

	elementId = elementId.strip;
	lastIndex = lastIndexOf(elementId,'-');
	if(lastIndex == -1 or elementId[lastIndex+1,elementId.length-1].to_i == 0)
		return elementId;
	else
		return elementId[0,lastIndex];
	end
end

##
#The following section is used to parse the ID number from the requirement stub
##

def parsePostfix(elementId)

	elementId = elementId.strip;
	lastIndex = lastIndexOf(elementId,'-');
	if(lastIndex == -1 or elementId[lastIndex+1,elementId.length-1].to_i == 0)
		return 0;
	else
		return elementId[lastIndex+1,elementId.length-1].to_i;
	end
end

##
#The following section is a helper method to find the last index of a given character in a given string
##

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

##
#The following section takes a requirement and recursively checks the owners until one has a requirement ID stub
#The method will then grab the latest ID from the HashMap, increment it by one, and then set the new ID
##

def fixId(element,req)
	if(element == $root or (element.getOwner() == $root and StereotypesHelper.getStereotypePropertyValue($root,$uniqueIDStubHolderStereotype,'uniqueIDStub').isEmpty()))
		Application.getInstance().getGUILog().log("Could not find valid prefix for: " + req.getName());
		return;
	elsif(!StereotypesHelper.getStereotypePropertyValue(element.getOwner(),$uniqueIDStubHolderStereotype,'uniqueIDStub').isEmpty())
		localId = StereotypesHelper.getStereotypePropertyValue(element.getOwner(),$uniqueIDStubHolderStereotype,'uniqueIDStub').get(0).strip;
		if(parsePrefix(localId) == localId)
			nextId = $lastRequirements.get(localId) + 1;
			Application.getInstance().getGUILog().log("Assigning " + localId + " " + nextId.to_s + " to '" + req.getName() + "'");
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
			return;
		end
	else
		Application.getInstance().getGUILog().log(element.getOwner().getName());
	end

	fixId(element.getOwner(),req);
end

##
#The following section is the main method of the macro
#The section calls the methods above and runs through the unmarked requirements to set their new IDs
##

begin
	SessionManager.getInstance().createSession("Populate_Requirement_Ids");

	$selectedNode = Application.getInstance().getProject().getBrowser().getContainmentTree().getSelectedNode().getUserObject();

	getLatestIds($root);
	findMissingIds($selectedNode);

	for req in $unmarkedRequirements
		fixId(req,req);
	end

ensure
	SessionManager.getInstance().closeSession();
end

##
#This macro was created to remove dependency relationships between requirements and create deriveReqt relations in their place.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager
CoreHelper = com.nomagic.uml2.ext.jmi.helpers.CoreHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
Finder = com.nomagic.magicdraw.uml.Finder

$project = Application.getInstance().getProject();

$elementsFactory = $project.getElementsFactory();

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');
$sysmlRequirementStereotype = StereotypesHelper.getStereotype($project,'Requirement',$sysmlProfile);
$sysmlInterfaceRequirementStereotype = StereotypesHelper.getStereotype($project,'interfaceRequirement',$sysmlProfile);
$sysmlDeriveRequirementStereotype = StereotypesHelper.getStereotype($project,'DeriveReqt',$sysmlProfile);

$packageToMoveTo = Finder.byQualifiedName().find($project,"Archived Dependencies");

$dependenciesToMove = java.util.ArrayList.new;
$abstractionsToInsert = java.util.HashMap.new;

def recursiveEASearch(element)
	if(element.getHumanType() == 'Dependency')
		supplier = CoreHelper.getSupplierElement(element);
		client = CoreHelper.getClientElement(element);
		if(StereotypesHelper.hasStereotype(supplier,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(supplier,$sysmlInterfaceRequirementStereotype))
			if(StereotypesHelper.hasStereotype(client,$sysmlRequirementStereotype) or StereotypesHelper.hasStereotype(client,$sysmlInterfaceRequirementStereotype))
				abstraction = $elementsFactory.createAbstractionInstance();
				CoreHelper.setSupplierElement(abstraction,supplier);
				CoreHelper.setClientElement(abstraction,client);
				StereotypesHelper.addStereotype(abstraction,$sysmlDeriveRequirementStereotype);
				$abstractionsToInsert.put(abstraction,element.getOwner());
				$dependenciesToMove.add(element);
			elsif(client.getHumanType() == 'Package')
				$dependenciesToMove.add(element);
			end
		elsif(supplier.getHumanType() == 'Package')
			$dependenciesToMove.add(element);
		end
	end
	for child in element.getOwnedElement()
		recursiveEASearch(child);
	end
end

begin
	SessionManager.getInstance().createSession("Fix Dependencies"); 

	recursiveEASearch($project.getPrimaryModel());

	for element in $abstractionsToInsert.keySet()
		element.setOwner($abstractionsToInsert.get(element));
	end

	if($packageToMoveTo == nil)
		$packageToMoveTo = $elementsFactory.createPackageInstance();
		$packageToMoveTo.setOwner($project.getPrimaryModel());
		$packageToMoveTo.setName("Archived Dependencies");
	end

	for element in $dependenciesToMove
		element.setOwner($packageToMoveTo);
	end
ensure
	SessionManager.getInstance().closeSession();
end
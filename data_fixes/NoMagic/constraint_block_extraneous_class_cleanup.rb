##
#This macro was created to remove duplicate Classes that were still found next to ConstrainBlocks.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper

$project = Application.getInstance().getProject();

$sysmlProfile = StereotypesHelper.getProfile($project,'SysML');

$sysmlConstraintBlockStereotype = StereotypesHelper.getStereotype($project,'ConstraintBlock',$sysmlProfile);

$elementsToRemove = java.util.ArrayList.new;

def recursiveEASearch(element)
	if(StereotypesHelper.hasStereotype(element,$sysmlConstraintBlockStereotype))
		for sibling in element.getOwner().getOwnedElement()
			if(sibling.getHumanType() == "Class")
				if(sibling.getName() == element.getName())
					$elementsToRemove.add(sibling);
				else
					for grandchild in sibling.getOwnedElement()
						if(grandchild.getHumanType() == "Property" and grandchild.getName() == element.getName())
							$elementsToRemove.add(sibling);
						end
					end
				end
			end
		end
	end
	for child in element.getOwnedElement()
    	recursiveEASearch(child);
	end
end

recursiveEASearch($project.getPrimaryModel());
ModelHelper.dispose($elementsToRemove);
# This script looks at a given Requirement and determines if a dervied 
# requirement shows up in both source to target and target to source 
# relationships.
require 'java'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML')

$requirementStereotype = StereotypesHelper.getStereotype($project, 'Requirement', $sysmlProfile)
$derivedRelationshipStereotype = StereotypesHelper.getStereotype($project, 'DeriveReqt', $sysmlProfile)

# This function looks at a Requirement and determines if it has any identical requirements 
# as targets or sources.
# Params:
# +requirement+:: Possible Requirement element from the containment tree.
def findSimilarTargetSource(requirement)
    if StereotypesHelper.hasStereotype(requirement, $requirementStereotype)
        requirementId = StereotypesHelper.getStereotypePropertyFirst(requirement, $requirementStereotype, "Id").to_s
        requirementFullName = requirementId +  " " + requirement.getName()
        targets = []
        sources = []
        for relation in requirement.get_directedRelationshipOfTarget()
            if StereotypesHelper.hasStereotype(relation, $derivedRelationshipStereotype)
                for source in relation.getSource()
                    requirementId = StereotypesHelper.getStereotypePropertyFirst(source, $requirementStereotype, "Id").to_s
                    fullName = requirementId +  " " + source.getName()
                    sources.push(fullName)
                end
            end
        end
        for relation in requirement.get_directedRelationshipOfSource()
            if StereotypesHelper.hasStereotype(relation, $derivedRelationshipStereotype)
                for target in relation.getTarget()
                    requirementId = StereotypesHelper.getStereotypePropertyFirst(target, $requirementStereotype, "Id").to_s
                    fullName = requirementId +  " " + target.getName()
                    targets.push(fullName)
                end
            end
        end
        # $logger.log("A: " + targets.to_s)
        # $logger.log("B: " + sources.to_s)
        overlaps = targets & sources
        unless overlaps.empty?
            $logger.log(requirementFullName + " has the following duplicates:")
            for overlap in overlaps
                $logger.log(overlap)
            end
        end
    end
end

# This function executes the function looking for similar targets as sources and then 
# parses through all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    findSimilarTargetSource(element)
    for child in element.getOwnedElement()
        recursiveTreeTraversal(child)
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Check Requirements for Same Target/Source")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
# This script looks for Requirements that do not have a target (orphaned). It 
# ignores LSR and OSS requirements as these are the top-level ones.
require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$noChecks = ["LSR", "OSS"]

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML')

$requirementStereotype = StereotypesHelper.getStereotype($project, 'Requirement', $sysmlProfile)
$derivedRelationshipStereotype = StereotypesHelper.getStereotype($project, 'DeriveReqt', $sysmlProfile)

# This function looks at a Requirement element to determine if there are 
# any target directed relationships.
# Params:
# +requirement+:: Possible Requirement element from the containment tree.
def findNoTargets(requirement)
    if StereotypesHelper.hasStereotype(requirement, $requirementStereotype)
        requirementId = StereotypesHelper.getStereotypePropertyFirst(requirement, $requirementStereotype, "Id").to_s
        requirementFullName = requirementId +  " " + requirement.getName()
        if $noChecks.include? requirementId.split('-')[0]
            return
        end
        targets = []
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
        if targets.empty?
            $logger.log(requirementFullName + " has no target requirements.")
        end
    end
end

# This function executes the function looking for no targets and then parses through 
# all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    findNoTargets(element)
    for child in element.getOwnedElement()
        recursiveTreeTraversal(child)
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Check Requirements for No Targets")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
# This script looks for OSS requirements to ensure that targets are either 
# other OSS requirements or LSR requirements.
require 'java'

Application = com.nomagic.magicdraw.core.Application
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$checkOnly = "OSS"

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML')

$requirementStereotype = StereotypesHelper.getStereotype($project, 'Requirement', $sysmlProfile)
$derivedRelationshipStereotype = StereotypesHelper.getStereotype($project, 'DeriveReqt', $sysmlProfile)

# This function looks at a OSS Requirement element to determine if there are 
# any target directed relationships that are not other OSS or LSR requirements.
# Params:
# +requirement+:: Possible Requirement element from the containment tree.
def findNoTargets(requirement)
    if StereotypesHelper.hasStereotype(requirement, $requirementStereotype)
        requirementId = StereotypesHelper.getStereotypePropertyFirst(requirement, $requirementStereotype, "Id").to_s
        requirementFullName = requirementId +  " " + requirement.getName()
        unless requirementId.include? $checkOnly
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
        # Remove OSS and LSR requirements from target list
        targets = targets.delete_if { |x| x.include? $checkOnly or x.include? "LSR" }
        unless targets.empty?
            $logger.log(requirementFullName + " has target requirements.")
            targets.each { |x| $logger.log(x) }
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
    session.createSession("Check OSS Requirements for No Targets")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
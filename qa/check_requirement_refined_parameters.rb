# This script looks at Requirements for all refining parameters
# and then checks the corresponding ConstraintBlocks/ConstraintElements 
# for valid expressions and units.
require 'java'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML');
$lsstProfile = StereotypesHelper.getProfile($project, 'LSST Profile');

$requirementStereotype = StereotypesHelper.getStereotype($project, 'Requirement', $sysmlProfile);
$refineStereotype = StereotypesHelper.getStereotype($project, 'Refine', $sysmlProfile)
$cbStereotype = StereotypesHelper.getStereotype($project, 'ConstraintBlock', $sysmlProfile)
$ceStereotype = StereotypesHelper.getStereotype($project, 'ConstraintElement', $lsstProfile);

# This function finds refining parameters via ConstraintBlocks/ConstraintElements 
# from the given Requirement.
# Params:
# +requirement+:: A Requirement element to look for refining parameters.
def findRefinedParameters(requirement)
    for relation in requirement.get_relationshipOfRelatedElement()
        if StereotypesHelper.hasStereotype(relation, $refineStereotype)
            ce = ModelHelper.getClientElement(relation)
            if StereotypesHelper.hasStereotype(ce, $ceStereotype) and StereotypesHelper.hasStereotype(ce, $cbStereotype)
                badval = false
                constraint = ce.get_constraintOfConstrainedElement().get(0)
                expression = constraint.getSpecification().getBody().get(0)
                paramUnit = StereotypesHelper.getStereotypePropertyFirst(ce, $ceStereotype, "unit")
                unless paramUnit.respond_to?(:name)
                    $logger.log(ce.getName() + ": Missing unit")
                    badval = true
                end
                unless expression != nil
                    $logger.log(ce.getName() + ": No expression found!")
                    badval = true
                end
                if badval
                    requirementId = StereotypesHelper.getStereotypePropertyFirst(requirement, $requirementStereotype, 'Id')
                    unless requirementId.to_s != ""
                        requirementId = requirement.getName()
                    end
                    $logger.log("Requirement Id: " + requirementId.to_s)
                end
            end
        end
    end
end

# This function executes the function looking for all refining parameters for a 
# requirement and then parses through all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    if StereotypesHelper.hasStereotype(element, $requirementStereotype)
        findRefinedParameters(element)
    end
    for child in element.getOwnedElement()
        recursiveTreeTraversal(child)
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Check Refined Parameters from Requirements")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
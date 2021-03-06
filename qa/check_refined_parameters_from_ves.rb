# This script looks at VerificationElements for all refining parameters
# and then checks the corresponding ConstraintBlocks/ConstraintElements 
# for valid expressions and units.
require 'java'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML')
$lsstProfile = StereotypesHelper.getProfile($project, 'LSST Profile')

$requirementStereotype = StereotypesHelper.getStereotype($project, 'Requirement', $sysmlProfile)
$refineStereotype = StereotypesHelper.getStereotype($project, 'Refine', $sysmlProfile)
$veStereotype = StereotypesHelper.getStereotype($project, 'VerificationElement', $lsstProfile)
$veRelationshipStereotype = StereotypesHelper.getStereotype($project, 'substantiate', $lsstProfile)
$ceStereotype = StereotypesHelper.getStereotype($project, 'ConstraintElement', $lsstProfile)

# This function finds refining parameters via ConstraintBlocks/ConstraintElements 
# from the given VerificationElement. It highlights elements that have no expressions 
# for constraints and missing units.
# Params:
# +requirement+:: A Requirement element to look for refining parameters.
def findRefinedParameters(element)
    for relation in element.get_relationshipOfRelatedElement()
        if StereotypesHelper.hasStereotype(relation, $veRelationshipStereotype)
            req = ModelHelper.getSupplierElement(relation)
            for relation in req.get_relationshipOfRelatedElement()
                if StereotypesHelper.hasStereotype(relation, $refineStereotype)
                    ce = ModelHelper.getClientElement(relation)
                    if StereotypesHelper.hasStereotype(ce, $ceStereotype)
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
                            reqId = StereotypesHelper.getStereotypePropertyFirst(req, $requirementStereotype, 'Id')
                            $logger.log("Requirement Id: " + reqId.to_s)
                        end
                    end
                end
            end
        end
    end
end

# This function executes the function looking for all refining parameters for a 
# VerficationElement and then parses through all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    if StereotypesHelper.hasStereotype(element, $veStereotype)
        findRefinedParameters(element)
    end
    for child in element.getOwnedElement()
        recursiveTreeTraversal(child)
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Check Refined Parameters via Verification Elements")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
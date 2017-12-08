require 'java'

Application = com.nomagic.magicdraw.core.Application
CoreHelper = com.nomagic.uml2.ext.jmi.helpers.CoreHelper
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$refinedParametersProp = 'RefinedParameters'

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML')
$lsstProfile = StereotypesHelper.getProfile($project, 'LSST Profile')

$requirementStereotype = StereotypesHelper.getStereotype($project, 'Requirement', $sysmlProfile)
$refineStereotype = StereotypesHelper.getStereotype($project, 'Refine', $sysmlProfile)
$veStereotype = StereotypesHelper.getStereotype($project, 'VerificationElement', $lsstProfile)
$veRelationshipStereotype = StereotypesHelper.getStereotype($project, 'substantiate', $lsstProfile)
$ceStereotype = StereotypesHelper.getStereotype($project, 'ConstraintElement', $lsstProfile)

# This function finds for all refining parameters for a VerficationElement and 
# creates a text block from the expressions and units and writes the text block 
# into the RefinedParameters attribute. 
# Params:
# +element+:: SysML element from the containment tree.
def findOrCreateRefinedParameters(element)
    $logger.log(element.getName())
    refinedParams = []
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
                        if paramUnit.respond_to?(:name)
                            paramUnit = paramUnit.name
                        else
                            paramUnit = ""
                            $logger.log(ce.getName() + ": Missing unit")
                            badval = true
                        end
                        if expression != nil
                            output = expression + "[" + paramUnit + "]"
                            refinedParams.push(output)
                        else 
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
    if refinedParams.size == 0
        $logger.log("No refined parameters")
    else
        original = StereotypesHelper.getStereotypePropertyFirst(element, $veStereotype, $refinedParametersProp)
        # 10.chr creates line separator for MagicDraw string view
        textBlock = refinedParams.join(10.chr)
        # Add text block to VE
        if original != textBlock
            #$logger.log(textBlock.to_s)
            StereotypesHelper.setStereotypePropertyValue(element, $veStereotype, $refinedParametersProp, textBlock)
        else
            $logger.log("No change in refined parameters.")
        end
    end
end

# This function executes the function looking for all refining parameters for a 
# VerficationElement and then parses through all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    if StereotypesHelper.hasStereotype(element, $veStereotype)
        findOrCreateRefinedParameters(element)
    end
    for child in element.getOwnedElement()
        recursiveTreeTraversal(child)
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Create Refined Parameters")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
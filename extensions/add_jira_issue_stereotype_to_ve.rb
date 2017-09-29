# This script add the JIRA Issue stereotype from the Syndeia plugin profile 
# to VerificationElements.
require 'java'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$lsstProfile = StereotypesHelper.getProfile($project, 'LSST Profile')
$syndeiaProfile = StereotypesHelper.getProfile($project, 'Syndeia_Profile')

$veStereotype = StereotypesHelper.getStereotype($project, 'VerificationElement', $lsstProfile)
$jiraStereotype = StereotypesHelper.getStereotype($project, 'JIRA_Issue', $syndeiaProfile)

# This function adds the JIRA Issue stereotype to a VerficationElement and 
# then parses through all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    if StereotypesHelper.hasStereotype(element, $veStereotype) and !StereotypesHelper.hasStereotype(element, $jiraStereotype)
        StereotypesHelper.addStereotype(element, $jiraStereotype)
    end
    for child in element.getOwnedElement()
        recursiveTreeTraversal(child)
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Add JIRA Issue Stereotype to Verification Elements")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
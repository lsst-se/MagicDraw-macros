# This script checks either Requirements or interfaceRequirements to see if 
# that requirement is used again in the derived by tree. It also checks for 
# duplicate requirements at any level.
#
# THe script requires the Ruby Gem rubytree.
require 'java'
require 'rubygems'
require 'tree'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
StereotypesHelper = com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper
SessionManager = com.nomagic.magicdraw.openapi.uml.SessionManager

$project = Application.getInstance().getProject()
$logger = Application.getInstance().getGUILog()

$sysmlProfile = StereotypesHelper.getProfile($project, 'SysML')
$lsstProfile = StereotypesHelper.getProfile($project, 'LSST Profile')

$printTree = false

# NOTE: Switch this to the correct stereotype you want to filter on.

stereotype = 'Requirement'
# stereotype = 'interfaceRequirement'

$requirementStereotype = StereotypesHelper.getStereotype($project, stereotype, $sysmlProfile)
$derivedRelationshipStereotype = StereotypesHelper.getStereotype($project, 'DeriveReqt', $sysmlProfile)

# This function determines in the element passed is a Requirement and then creates 
# a Tree::TreeNode to capture all DerivedBy source requirements. If a circular reference 
# is present in the tree, a SystemStackError is generated.
# Params:
# +requirement+:: A possible Requirement element from the containment tree.
# Returns:
# A Tree::TreeNode containing all of the paths to DerivedBy requirements.
def findRequirementsTree(requirement)
    reqTree = nil
    if StereotypesHelper.hasStereotype(requirement, $requirementStereotype)
        begin
            requirementName = requirement.getName()
            requirementId = StereotypesHelper.getStereotypePropertyFirst(requirement, $requirementStereotype, "Id").to_s
            fullName = requirementId + " " + requirementName
            reqTree = Tree::TreeNode.new(fullName)    
            # $logger.log("Root: " + fullName)
            recurseDerivedRequirements(requirement, reqTree)
        rescue SystemStackError
            $logger.log("Recursive Issue2: " + fullName)
            return reqTree
        end
    end
    return reqTree
end

# This function looks at a Requirement and builds a tree based on all DerivedBy sources 
# of the element. It passed along any sources to this function again to continue the 
# discovery process.
# Params:
# +requirement+:: A possbile Requirement element.
# +treeNode+:: Instance of a Tree::TreeNode for collecting path information.
def recurseDerivedRequirements(requirement, treeNode)
    # $logger.log(treeNode.name)
    derivedReqs = []
    if StereotypesHelper.hasStereotype(requirement, $requirementStereotype)
        #for relation in requirement.get_relationshipOfRelatedElement()
        for relation in requirement.get_directedRelationshipOfTarget()
            if StereotypesHelper.hasStereotype(relation, $derivedRelationshipStereotype)
                # derivedReqs.push(ModelHelper.getClientElement(relation))
                derivedReqs.push(relation.getSource().get(0))
                # $logger.log("H: " + derivedReqs[-1].getName())
            end
        end
    end
    unless derivedReqs.empty?
        # $logger.log("DR: " + derivedReqs.size.to_s)
        # for dr in derivedReqs
        #     $logger.log(dr.name)
        # end
        for derivedReq in derivedReqs
            # $logger.log("D: " + derivedReq.getName())
            requirementId = StereotypesHelper.getStereotypePropertyFirst(derivedReq, $requirementStereotype, "Id").to_s
            # requirementId = ""
            childNode = Tree::TreeNode.new(requirementId + " " + derivedReq.getName())
            recurseDerivedRequirements(derivedReq, childNode)
            begin
                treeNode.add(childNode)
            rescue RuntimeError
                $logger.log("Duplicate entry: " + childNode.name)
                $logger.log(treeNode.name)
            end
        end
    end
    return
end

# This function looks at all the leaf to root node paths in the tree to determine 
# if the root node shows up anywhere in the path. If it does, the element above it 
# is highlighted.
# Params:
# +reqTree+:: A Tree::TreeNode instance containing the path information. 
def checkForDuplicateRoots(reqTree)
    reqTreeRootName = reqTree.root.name
    if reqTree.size == 1
        # $logger.log(reqTreeRootName + " has no derived objects")
        return
    end
    counter = 0
    for leaf in reqTree.each_leaf
        ancestry = leaf.parentage
        ancestry.unshift(leaf)
        ancestry.delete_at(-1)
        duplicates = ancestry.each_index.select { |i| ancestry[i].name == reqTreeRootName }
        for duplicate in duplicates
            $logger.log(ancestry[duplicate + 1].name + " refers to " + reqTreeRootName)
            counter += 1
        end
        if $printTree
            $logger.log("L: " + leaf.name)
            for node in ancestry
                $logger.log(node.name)
            end
        end
    end
    # if counter == 0
    #     $logger.log(reqTreeRootName + " has no cyclical requirements")
    # end
end

# This function executes the function that gathers requirements tree and then 
# executes the function for finding duplicate root nodes, finally it  
# parses through all owned elements from the given one.
# Params:
# +element+:: SysML element from the containment tree.
def recursiveTreeTraversal(element)
    begin
        requirementsTree = findRequirementsTree(element)
        unless requirementsTree == nil
            checkForDuplicateRoots(requirementsTree)
        end
        for child in element.getOwnedElement()
            recursiveTreeTraversal(child)
        end
    rescue SystemStackError
        $logger.log("Recursive Issue1: " + element.getName())
    end
end

begin
    session = SessionManager.getInstance()
    session.createSession("Check Requirements for Circular Logic")
    selectedNode = $project.getBrowser().getContainmentTree().getSelectedNode().getUserObject()
    recursiveTreeTraversal(selectedNode)
ensure
    session.closeSession()
end
Quality Assurance Scripts
=========================

These are scripts used to check model data. They **DO NOT** correct the data.

``check_oss_requirements_for_no_subsystem_targets.rb``: Check all OSS requirements and ensures that 
only OSS and LSR requirements are targets.

``check_refined_parameters_from_ves.rb``: Checks ConstraintBlock/ConstraintElements for valid expressions and units via VerificationElements.

``check_requirement_refined_parameters.rb``: Checks ConstraintBlock/ConstraintElements for valid expressions and units via Requirements.

``check_requirements_for_circularrefs_and_duplicates.rb``: This script requires the Ruby Gem ``rubytree``. Checks a stereotype to see if any derived relationships have circular references.

``check_requirements_for_no_targets.rb``: This script looks at Requirements and determines if it has any targets.

``check_requirements_for_same_target_source.rb``: This script looks at Requirements and determines if source and target derived relationships point to the same requirement.

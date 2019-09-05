# Simple sed to generate a markdown table for terraform module outputs
# The output.tf file must be in the following structure
#
# output "name" {
#  description = "output Description"
#  value       = xxxxx
# }
#
#######################################
# PS: The line order must be followed #
#######################################
#
#############################################################################
# Table columns output:
#
# | Name | Description |
#############################################################################

cat ../output.tf     |
    sed 's/["{}]//g' |
    sed -n '/^output */{
        s//| /;
        N;
        s/\n *description *= *\(.*\)/| \1 |/;
        p
    }'               |
    sed '1i | Name | Description |\n|:-----|:------------|'

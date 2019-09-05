# Simple sed to generate table markdown to variable inputs
# Variable **must** be defined with the following structure:
#
#### for required variable
# variable "name" {
#  description = "variable description"
#  type        = string
# }
#
#### for non required variable
# variable "lb_description" {
#  description = "variable description"
#  type        = string
#  default     = ""
# }
#
###############################
# The line order is important #
###############################
#
##############################################################
# Ouput:
#
# Table columns output:
# | Name | Description | Type | Default | Required |
##############################################################

cat ../vars.tf       |
    sed 's/["{}]//g' |
    sed -n '/^variable /{
        s//|/;
        N;
        s/\n *description *= */ | /;
        N;
        s/\n *type *= */ | /;
        N;
        /\n *default *= *$/{
            s// | `-` | no |/
            tend
        }
        /\n *default *= *\(.\+\)/{
            s// | `\1` | no |/
            tend
        }
        s/\n.*/ | - | **yes** |/
        :end;
        p;}'         |
    sed '1i | Name | Description | Type | Default | Required |\
|:-----|:------------|:----:|:-------:|:--------:|'


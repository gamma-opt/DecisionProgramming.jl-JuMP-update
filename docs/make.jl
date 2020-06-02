using Documenter
using DecisionProgramming

makedocs(
    sitename = "DecisionProgramming",
    format = Documenter.HTML(),
    modules = [DecisionProgramming]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#

{Directory} = require "atom"

module.exports =
  repositoryForPath: (goalPath) ->
    if goalPath
      directory = new Directory goalPath
      return atom.project.repositoryForDirectory directory
    Promise.resolve(null)

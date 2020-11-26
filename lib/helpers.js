const { Directory } = require('atom')

module.exports = {
	repositoryForPath (goalPath) {
		if (goalPath) {
			const directory = new Directory(goalPath)
			return atom.project.repositoryForDirectory(directory)
		}
		return Promise.resolve(null)
	},
}

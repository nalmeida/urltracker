module.exports = function (eleventyConfig) {
	eleventyConfig.addPassthroughCopy({ "demo/*.gif": "docs/demo" });
	return {
		dir: {
			input: "./src",
			output: "./dist",
			includes: "_includes"
		}
	};
};
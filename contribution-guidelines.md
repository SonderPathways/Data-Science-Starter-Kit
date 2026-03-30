# Contribution guidelines

This is a collaborative repository, and therefore participants or end users are expected to contribute to it. Being an open repository provides several advantages typically associated with free and open-source software.

Among these advantages is the fact that the code can be cost-effective for future developments, as well as customizable and adaptable to the needs of different user groups. It also fosters community-driven innovation and is not restricted by any specific vendor. Most importantly, it provides enhanced security and transparency, since the code is open and can be audited by anyone involved in the Pathways project ecosystem.

This openness can lead to faster error detection and quicker bug fixes, as well as the identification of potential inconsistencies originating from early versions of the scripts. If working groups conduct preliminary reviews of these issues, the repository will progressively improve over time, ultimately providing stronger guarantees of proper functionality and alignment with the project’s original objectives.

In addition, it is important to highlight that there are collaboration guidelines in place. Initially, the repository will be accessible to individuals directly involved in the Pathways project, but it will gradually be opened to other users engaging with the ecosystem. These users will be able to propose changes or improvements through their personal or organizational GitHub accounts.

Such contributions should follow the standard lifecycle of collaborative development on GitHub. For instance, anyone interested in contributing may request access to the repository and, once granted, submit meaningful improvements to existing examples via a pull request, following the established review and approval process managed by the repository administrator.

Similarly, if a user or practitioner develops a robust example in the context of fieldwork or new public health projects—one that is substantially different from existing materials—they may create a new folder containing a description of the analysis case in a .md (Markdown) file. In this README.md file, they can fully document their development, innovation, or ad hoc analysis, and include the corresponding script in either R or Python. This contribution can then be submitted for review and potential inclusion in the repository’s core set of community-relevant examples.

## Technical Instructions for Contribution

To contribute a new data analysis use case or improve existing ones, please follow these technical steps based on standard FOSS community practices:

### 1. Clone the Repository
Start by cloning the repository to your local machine:
```bash
git clone https://github.com/your-organization/ds-starter-kit.git
cd ds-starter-kit
```

### 2. Setup Your Environment
Ensure you have the necessary environments for R and Python as described in the root `readme.md`.
- **Python:** Use `pipenv` or `venv` to manage dependencies.
- **R:** Install required packages using the `r-packages.txt` file or as specified in the specific use case `readme.md`.

### 3. Create a New Branch
Never work directly on the `main` branch. Create a feature branch for your contribution:
```bash
git checkout -b feature/your-analysis-name
```

### 4. Structure Your Contribution
If you are adding a new use case:
1. Create a new subdirectory under `Post-segmentation analysis/`.
2. Include a `readme.md` file in that folder explaining:
   - **Objective:** What problem does this analysis solve?
   - **Inputs:** What data files are required? (Use placeholders for sensitive data).
   - **Workflow:** A summary of the steps taken.
3. Provide the analysis script in both **R** and **Python** (using `rpy2` where consistency with R packages like `survey` is required).

### 5. Local Validation
Verify that your scripts run correctly in your local environment. Ensure that:
- Code is clean and well-commented.
- No sensitive information (API keys, credentials, PII) is included in the scripts or documentation.

### 6. Commit and Push
Use clear and descriptive commit messages:
```bash
git add .
git commit -m "Add: [Description of the new use case]"
git push origin feature/your-analysis-name
```

### 7. Submit a Pull Request (PR)
- Go to the repository on GitHub and open a Pull Request from your branch to `main`.
- Provide a clear description of your changes in the PR template.
- Wait for the maintainers to review your contribution. Be prepared to make iterative improvements based on feedback.

By following these steps, you help maintain the technical integrity and collaborative spirit of the Pathways project.
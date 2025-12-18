# Pathways Data Science Starter Kit

This Starter Kit provides a collection of practical, ready-to-use examples for conducting common analytical workflows using R, Python, R Markdown, and Jupyter Python Notebooks. It is designed to help data scientists, researchers, partner organizations, and external collaborators quickly understand how to work with the datasets managed by our Data Science team and to reuse these examples as the foundation of their own work.

The primary goal of this Starter Kit is to promote reproducibility, consistency, and shared analytical standards across projects. Each example illustrates a frequently used pattern—such as data cleaning, exploratory analysis, visualization, modeling, or reporting—implemented in multiple languages so users can choose the environment that best fits their workflow.

Beyond code, this repository also includes recommended project structures, documentation practices, and version control guidelines to support seamless collaboration. Whether you are conducting a quick exploratory study, developing a full analytical workflow, or integrating results into your own tools, this Starter Kit provides a reliable, open-source foundation to build on.

## Repository Examples Index

- **Health utilization score**
  - [Lagos DHS health utilization](Post-segmentation%20analysis/health%20utilization%20score/lagos_health_utilization/readme.md)
  - [Nigeria Pathways survey health utilization](Post-segmentation%20analysis/health%20utilization%20score/NN_PWS_health_utilization/readme.md)
- **Predicted outcomes with updated weights** – [Senegal survey-weighted logistic example](Post-segmentation%20analysis/predicted_outcomes_updated_weights/readme.md)
- **Random forest feature discovery** – [Nigeria predictor importance workflow](Post-segmentation%20analysis/random_forest_feature_discovery/readme.md)
- **Segment population estimates** – [UN WPP + DHS methodology](Post-segmentation%20analysis/Segment%20population%20estimates/readme.md)
- **U5MR analyses**
  - [Overview](Post-segmentation%20analysis/U5MR/readme.md)
  - [DHS-based U5MR scripts (Kenya, Northern Nigeria)](Post-segmentation%20analysis/U5MR/U5MR%20for%20DHS%20Solutions/readme.md)
- **Use segments to predict outcomes**
  - [Overview](Post-segmentation%20analysis/Use%20segment%20to%20predict%20outcomes/readme.md)
  - [Northern Nigeria Pathways logistic models](Post-segmentation%20analysis/Use%20segment%20to%20predict%20outcomes/north_nigeria_pathways/readme.md)
- **Validate hypotheses from qualitative research** – [Senegal qual-to-quant workflow](Post-segmentation%20analysis/Validate%20hypotheses%20from%20qual/readme.md)

## 1. Python environment

Currently, the environment used to export reports is **HTML-reports-emoTyqDj** and it requires to be activated from terminal using this:

```bash
source /Users/youruser/.local/share/virtualenvs/HTML-reports-emoTyqDj/bin/activate
```

Please adapt this instruction using *youruser* and the propper path according your own folder structure in your machine.

And this environment can be replicated with two options:

1. **Using Pipenv** – with `Pipfile` and `Pipfile.lock`
2. **Without Pipenv** – using `requirements.txt`

---

### 1.1. Prerequisites

Before starting, ensure Python is installed.

| OS      | Install Python via Terminal / Command Line                                                                                                      |
| ------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| macOS   | `brew install python` (or download from [https://python.org](https://python.org))                                                               |
| Windows | Download from [https://python.org](https://python.org) and run the installer. Make sure to select **"Add Python to PATH"** during installation. |

Verify Python installation:

```bash
python --version
# or
python3 --version
```

---

### 1.2. Option 1: Using Pipenv

Pipenv is a convenient tool to manage multiple Python environments in one single machine. Use this approach if you already have some experience with Python Environments and you want to isolate the installation from other projects.

Pipenv is not the only alternative to admin multiple Python environments. There are other popular tools, like pure Python (venv), Conda, Virtualenv, pyenv-virtualenv, etc. Depending on your choise, you can adapt/modify this steps with some other approach to achieve the same results.

#### 1.2.1. Step 1: Install Pipenv

##### On macOS:

```bash
brew install pipenv
```

##### On Windows:

```bash
pip install pipenv
```

> Use `python -m pip install pipenv` if `pip` isn't available globally.

---

#### 1.2.2. Step 2: Install the Environment

Navigate to the folder that contains the `Pipfile` and `Pipfile.lock`.

```bash
cd path/to/your/project
pipenv install --ignore-pipfile
```

This installs all dependencies exactly as locked.

---

#### 1.2.3. Step 3: Run Python or Jupyter

To enter the environment:

```bash
pipenv shell
```

Then run:

```bash
python your_script.py
# or
pipenv run jupyter notebook
```

---

### 1.3. Option 2: Without Pipenv (Using `requirements.txt`)

This is a simple approach, recommended if this will be the only Python project in your machine.

#### 1.3.1. Step 1: Create a Virtual Environment (optional but recommended)

##### On macOS / Linux:

```bash
python3 -m venv venv
source venv/bin/activate
```

##### On Windows:

```cmd
python -m venv venv
venv\Scripts\activate
```

---

#### 1.3.2. Step 2: Install Dependencies

Assuming you have a `requirements.txt` file:

```bash
pip install -r requirements.txt
```

You can create it from a Pipenv environment using:

```bash
pipenv run pip freeze > requirements.txt
```

---

#### 1.3.3. Step 3: Run Scripts or Notebooks

```bash
python your_script.py
# or
jupyter notebook
```

---

### 1.4. Switching Between Environments

* **Activate Pipenv**:

  ```bash
  pipenv shell
  ```

* **Activate venv (manual virtualenv)**:

  * macOS/Linux: `source venv/bin/activate`
  * Windows: `venv\Scripts\activate`

* **Deactivate**:

  ```bash
  deactivate
  ```

---

### 1.5. Summary

| Option           | Tool       | Pros                                | When to Use                   |
| ---------------- | ---------- | ----------------------------------- | ----------------------------- |
| Pipenv           | Pipenv     | Exact version control, reproducible | Recommended for collaboration |
| requirements.txt | venv / pip | No extra tools, simple setup        | Good for basic workflows      |


## 2. R Environment Setup for Quant Reports (macOS and Windows)

This guide explains how to install the required R packages for running notebooks or scripts that include R code via `rpy2` or within RStudio. It assumes you have a file named `r-packages.txt` listing the required packages (one per line).

---

### 2.1. Prerequisites

### 2.2. Install R

| OS      | Installation Method                                                                               |
| ------- | ------------------------------------------------------------------------------------------------- |
| macOS   | `brew install --cask r` or download from [https://cran.r-project.org](https://cran.r-project.org) |
| Windows | Download and install from [https://cran.r-project.org](https://cran.r-project.org)                |

### 2.3. (Optional) Install RStudio

RStudio is a user-friendly IDE for R:

* macOS: `brew install --cask rstudio`
* Windows/macOS: [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)

---

### 2.4. Installation of R Packages

Make sure the `r-packages.txt` file is located in the working directory. Each line should contain the name of a package to install, like:

```
survey
haven
dplyr
tidyr
ggplot2
```

### 2.5. Open R or RStudio, and run:

```r
# Read the list of required packages from the file
packages <- readLines("r-packages.txt")

# Install only the ones that are not already installed
install.packages(setdiff(packages, rownames(installed.packages())))
```

> This ensures your environment includes exactly the packages listed.

---

### 2.6. Verifying Installation

You can verify that all required packages were installed with:

```r
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing) == 0) {
  message("All packages installed successfully.")
} else {
  message("Missing packages:", paste(missing, collapse=", "))
}
```

## 3. Command to export reports

Jupyter Notebooks allow you to combine code with rich text and interactive visualizations, which can be easily exported in a variety of formats, including HTML. In this way, a non-technical audience, who may not have tools such as integrated development environments installed on their computer and who have no interest in the code used in the analysis, can easily access the results from a browser.

Please take in account that some specific libraries are used to export reports with the legacy format used in Pathways, preovious to the incororation of the QPRs to the Segment Explorer:

- [nbconvert](https://nbconvert.readthedocs.io/en/latest/): main library used to export to formats like PDF and HTML
- [Pretty Jupyter](https://pretty-jupyter.readthedocs.io/en/latest/index.html): package that allows to create dynamic HTML reports, including Table of Contents, code folding, tabs, etc. It depends of themes/templates
- Templates: the current method to export reports uses `quant-lite`template, based in `quant-profile`, in turn based in `pj`. These templates are created using ***[jinja 2](https://jinja.palletsprojects.com/en/stable/)*** template engine.

To export a valid HTML file from a Python Notebook containing the report, it is necessary to run this command (please remember that packages like ***nbconvert*** and ***Pretty Jupyter*** must be available in your system to use this command):

```bash
jupyter nbconvert 'NN PWS1 2022 v2/nn-pws-quant-report-2025-04-08.ipynb' \
    --to html \
    --template quant-lite \
    --TemplateExporter.extra_template_basedirs=./templates \
    --TagRemovePreprocessor.enabled=True \
    --TagRemovePreprocessor.remove_cell_tags='{"hide"}'
```

Lets explain each part of the command:

```bash
jupyter nbconvert 'NN PWS1 2022 v2/nn-pws-quant-report-2025-04-08.ipynb' \
```

↑ "jupyter" is the main command, followed by the path to the notebook file. The character "\\" is used in bash to connect a multi-line command.

```bash
    --to html \
```

↑ the flag to chose HTML as the exported format

```bash
    --template quant-lite \
    --TemplateExporter.extra_template_basedirs=./templates \
```

↑ These flags will indicate the final format with which the HTML file will be exported. "quant-lite" is a custom template created specifically for Pathways, and it will enable some features like the format of table of contents, layout, colors, etc., among others. The "quant-lite" folder must be copied into the working folder, to match the path indicated in the second line, in this case is "/template".

```bash
    --TagRemovePreprocessor.enabled=True \
    --TagRemovePreprocessor.remove_cell_tags='{"hide"}'
```

↑ Tags are a Jupyter Notebook's feature that allows to set tags to specific cells. In the QPR, the tag "hide" is used to "hide" some content not relevant for the final exported file, so this two lines will remove that specific cells. 

## 4. QPR header

Depending in the template, some directives need be used during the export process and as content of the exported file. These data, in Yaml format, is stored in the first cell of each notebook, as metadata. This is an example:

```Yaml
title: Overview - Northern Nigeria Segmentation
author: Sonder Segmentation Science WS Team
date: "{{ datetime.now().strftime('%Y-%m-%d') }}"
version: Pathways 2022 - v2.
favicon: 🇳🇬
output:
    general:
        input: false
    html:
        toc_depth: 4
```

- *title* is used as the document title, visible in the browser tab.
- *author* is used in the top header of the 
report
- *date* is used in the top header of the 
report
- *version* is used in the top header of the 
report
- *output.general.input* shows or hide input cells
- *output.html.toc_depth* is used to build the structure of the Table of Contents.

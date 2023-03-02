#-----------------------------------------------------------------------------
# Configuration file for jupyter nbconvert
#-----------------------------------------------------------------------------
import os
c = get_config()

# Set default PDF conversion command
# See: https://nbconvert.readthedocs.io/en/latest/config_options.html
c.PDFExporter.verbose = True
c.PDFExporter.latex_count = 1
c.PDFExporter.latex_command = [os.path.expanduser('~/miniconda3/bin/tectonic'), '{filename}']  # noqa: E501

# Nice html exporter
c.Exporter.preprocessors = [
    'nbconvert.preprocessors.TagRemovePreprocessor',
    'nbconvert.preprocessors.RegexRemovePreprocessor',
    'nbconvert.preprocessors.coalesce_streams',
    'nbconvert.preprocessors.CSSHTMLHeaderPreprocessor',
    'nbconvert.preprocessors.HighlightMagicsPreprocessor',
    # 'nbconvert.preprocessors.ExtractOutputPreprocessor',
]

# Previously tried to use hidecode.tplx template but this is obsolete
# See: https://stackoverflow.com/a/46251213/4970632
# c.LatexExporter.template_paths = ['.', os.path.expanduser('~/.jupyter')]
# c.TemplateExporter.template_paths = ['.', os.path.expanduser('~/.jupyter')]

// Jupyter.keyboard_manager.command_shortcuts.add_shortcut('r', {
//     help : 'run cell',
//     help_index : 'zz',
//     handler : function (event) {
//         IPython.notebook.execute_cell();
//         return false;
//     }}
// );
// Custom operator for commenting
// (similar to commentary by Tim Pope)
// this woks with visual selection ('vipc.') and with motions ('c.ip')
// looks just like python

// THE BELOW FAILED
//require(['nbextensions/vim_binding/vim_binding'], function() {
//    CodeMirror.Vim.defineOperator("comment_op", function(cm) {
//        cm.toggleComment();
//    });
//    CodeMirror.Vim.mapCommand("c.", "operator", "comment_op", {});
//});

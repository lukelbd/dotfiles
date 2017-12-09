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

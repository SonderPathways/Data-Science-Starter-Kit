$(document).ready(function () {

    /**
     * ------------- TOC ----------------
     * ----------------------------------
     */

    var $toc = $("#toc-container");
    if (!$toc.length) return;

    // Create the root <ul> for the TOC
    var tocList = $("<ul></ul>");
    // Initialize currentLevel to 0 and create a stack that holds the current nested <ul>
    var currentLevel = 0;
    var levelStack = [tocList]; // levelStack[0] is the root

    // Process headers h1, h2, h3 in the order they appear
    $("h2, h3, h4").each(function () {
        var $header = $(this);
        // Determine heading level from tag name (e.g. "h2" becomes 2)
        var level = parseInt(this.tagName.substring(1), 10);
        if (isNaN(level)) { level = 1; }

        // Create a unique ID if missing so we can link to the header
        if (!$header.attr("id")) {
            var newId = "toc-id-" + Math.random().toString(36).substr(2, 9);
            $header.attr("id", newId);
        }
        var id = $header.attr("id");
        var text = $header.text().trim().slice(0, -1);

        // Create the list item and link
        var $li = $("<li></li>").append($("<a></a>").attr("href", "#" + id).text(text));

        // Adjust the stack based on heading level changes
        if (level > currentLevel) {
            // For each level we're going deeper, create a new nested <ul>
            for (var i = currentLevel; i < level; i++) {
                var $subList = $("<ul></ul>");
                // Append the new <ul> to the last item of the current last <ul>
                // (if no li exists, simply append the sublist to the current list)
                var $lastItem = levelStack[levelStack.length - 1].children("li").last();
                if ($lastItem.length) {
                    $lastItem.append($subList);
                } else {
                    levelStack[levelStack.length - 1].append($subList);
                }
                levelStack.push($subList);
            }
        } else if (level < currentLevel) {
            // Pop out from the stack to go back to the appropriate level
            for (var i = currentLevel; i > level; i--) {
                levelStack.pop();
            }
        }
        // Update currentLevel to the current heading's level
        currentLevel = level;
        // Append the new <li> to the <ul> at the top of the stack
        levelStack[levelStack.length - 1].append($li);
    });

    // Finally, append the built TOC to the container
    $toc.append($("ul > ul", tocList).first());


    /**
     * ------------- TABLES ----------------
     * -------------------------------------
     */

    // Only some tables are modified
    $("table").each(function () {

        // add a class if the table is too large
        if ($(this).height() > 600) {
            // Find all the tables and wrap it in a new div
            $(this).wrap('<div class="table-container limited"></div>');
        }
        else {
            $(this).wrap('<div class="table-container"></div>');
        }

        $(this).css("margin-bottom", "0px");
    });

    $("tr").css("text-align", "left");
});
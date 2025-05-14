# Signal Plus for Godot

This is a plugin for the Godot Engine that enhances the scripting workflow by providing intelligent code completion for connecting signals in GDScript.

## Features

* **Smart Signal Connection Completion:** When you are writing code to connect a signal (likely using the `connect` method), pressing `Ctrl` + `Alt` + `Space` will trigger intelligent code completion.
* **Method and Lambda Suggestions:** The plugin suggests both regular methods and lambda functions as potential handlers for the signal.
* **Visual Differentiation:** Suggestions for regular methods and lambda functions are displayed with distinct icons.
* **Automatic Code Generation:** Upon selecting a suggestion, the plugin automatically generates the basic structure of the method or lambda function, including the necessary arguments based on the signal's parameters.

## How to Use

1.  Install the plugin through the Godot Asset Library or by manually adding the `addons/signal_plus` folder to your project.
2.  Enable the plugin in your Project Settings under the "Plugins" tab.
3.  When you are in a GDScript and writing code involving the `connect` method:
    * Ensure your cursor is in a position where you would typically define the method to connect to the signal.
    * Press `Ctrl` + `Alt` + `Space`.
    * A list of suggested method names (or a lambda structure) will appear.
    * Select the desired option. The plugin will then insert the basic function structure into your script.

## Installation

### Through Godot Asset Library

1.  Open your Godot project.
2.  Go to the "AssetLib" tab.
3.  Search for "Signal Plus".
4.  Install the plugin.
5.  Enable the plugin in Project Settings -> Plugins.

### Manual Installation

1.  Download or clone this repository.
2.  Create an `addons` folder in the root of your Godot project (if it doesn't exist).
3.  Copy the `signal_plus` folder into the `addons` folder.
4.  Enable the plugin in Project Settings -> Plugins.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, feel free to open an issue or submit a pull request.

## License

MIT License

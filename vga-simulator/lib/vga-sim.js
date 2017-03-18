$(document).ready(function() {

	function canvasManager() {
		this.element = null;
		this.ctx = null;

		this.init = function (canvasElement) {
			this.element = canvasElement;
			this.ctx = canvasElement.getContext('2d');
		};

		this.createImageData = function () {
			return this.ctx.createImageData(this.element.width, this.element.height);
		};

		this.setPixel = function (imageData, x, y, r, g, b, a) {
			index = (x + y * imageData.width) * 4;
			imageData.data[index + 0] = r;
			imageData.data[index + 1] = g;
			imageData.data[index + 2] = b;
			imageData.data[index + 3] = a;
		};

		this.putImageData = function (imageData, x, y, alias) {
			alias = alias || true;

			this.ctx.webkitImageSmoothingEnabled = alias;
			this.ctx.mozImageSmoothingEnabled = alias;
			this.ctximageSmoothingEnabled = alias;

			//console.log("Copying to canvas " + Date.now());
			this.ctx.putImageData(
				imageData,
				x, // at coords 0,0
				y
			);
		};

		this.fixCanvasForPPI = function (width, height) {

			width = parseInt(width);
			height = parseInt(height);

			// finally query the various pixel ratios
			var devicePixelRatio = window.devicePixelRatio || 1;
			var backingStoreRatio = this.ctx.webkitBackingStorePixelRatio 
				|| this.ctx.mozBackingStorePixelRatio 
				|| this.ctx.msBackingStorePixelRatio 
				|| this.ctx.oBackingStorePixelRatio 
				|| this.ctx.backingStorePixelRatio 
				|| 1;

			var ratio = devicePixelRatio / backingStoreRatio;

			// ensure we have a value set for auto.
			// If auto is set to false then we
			// will simply not upscale the canvas
			// and the default behaviour will be maintained
			if (typeof auto === 'undefined') {
				auto = true;
			}

			// upscale the canvas if the two ratios don't match
			if (auto && devicePixelRatio !== backingStoreRatio) {

				$(this.element).attr({
					'width': width * ratio,
					'height': height * ratio
				});

				$(this.element).css({
					'width': width + 'px',
					'height': height + 'px'
				});

				// now scale the context to counter
				// the fact that we've manually scaled
				// our canvas element
				this.ctx.scale(ratio, ratio);

			}
			// No weird ppi so just resize canvas to fit the tag
			else {
				$(this.element).attr({
					'width': width,
					'height': height
				});

				$(this.element).css({
					'width': width + 'px',
					'height': height + 'px'
				});
			}
		};

		this.resizeCanvas = function (width, height) {
			oldWidth = this.element.width;
			oldHeight = this.element.height;

			imageData = this.ctx.getImageData(0, 0, oldWidth, oldHeight);

			var newCanvas = $("<canvas>")
				.attr("width", imageData.width)
				.attr("height", imageData.height)[0];
			newCanvas.getContext("2d").putImageData(imageData, 0, 0);

			this.fixCanvasForPPI(width, height);

			this.ctx.clearRect(0, 0, width, height);
			this.ctx.drawImage(newCanvas, 0, 0, oldWidth, oldHeight, 0, 0, width, height);
		};
	}

	// Make your own vgaDecoder object before using
	function vgaDecoder() {
		this.resX = 800;
		this.resY = 600;
		this.pixelClockRate = 50; // in MHz
		
		this.backPorchX = 56;
		this.backPorchY = 38;

		this.hCounter = 0;
		this.vCounter = 0;
		
		this.backPorchXCount = 0;
		this.backPorchYCount = 0;

		this.numLinesSkipped = 0;

		this.file_lines = [];

		this.handleLinesStartTime = -1;
		this.handeLinesExecTime = 0;

		this.last_hSync = -1;
		this.last_vSync = -1;
		

		this.lastPacketTime = 0; // Time from the last line
		this.timeSinceLastPixel = 0; // Time since we added a pixel to the canvas

		this.canvas_manager = null;
		this.frameHolder = null;
		this.imageArray = [];

		this.stopHandlingLines = false; // Use this to stop the handleLines loop
		this.shouldLog = false; // Use this to print logging messages to the console
		
		
		this.init = function (resX, resY, pxClkRate, canvasMan) {
			this.resX = parseInt(resX);
			this.resY = parseInt(resY);
			this.pixelClockRate = parseFloat(pxClkRate);

			this.canvas_manager =  canvasMan;

			this.restart();
		};


		this.restart = function () {
			this.hCounter = 0;
			this.vCounter = 0;

			
			this.backPorchXCount = 0;
			this.backPorchYCount = 0;
			
			this.numLinesSkipped = 0;

			this.file_lines = [];

			this.handleLinesStartTime = -1;
			this.handeLinesExecTime = 0;

			this.last_hSync = -1;
			this.last_vSync = -1;
			
			this.lastPacketTime = 0; // Time from the last line
			this.timeSinceLastPixel = 0; // Time since we added a pixel to the canvas

			this.imageArray = [];
			
			this.stopHandlingLines = false;
		};
		
		this.log = function(text) {
			if(this.shouldLog)
				console.log(text);
		};

		this.handleFileContent = function (text) {
			this.file_lines = text.split('\n');
			this.log("Split out lines at new line: " + Date.now());

			// Take care of the lines
			this.handleLines(0);


		};

		this.handleLines = function (lineIndex) {

			numLinesPerIteration = 5000;

			// Only do numLinesPerIteration lines at a time
			for (var i = 0; i < numLinesPerIteration; i++) 
			{
				if (this.handleLinesStartTime < 0) 
					this.handleLinesStartTime = Date.now();

				// If there are no more lines
				// Get outta here
				if (lineIndex >= this.file_lines.length - 1) 
					break;
				
				// If we requested to stop, do it
				if (this.stopHandlingLines)
				{
					// Now getta outta here
					break;
				}

				// See if the line matches and collect data from line
				matches = this.file_lines[lineIndex].match(/^([0-9]+) (fs|ps|ns|us|ms|sec|min|hr): (0|1|U|X|Z) (0|1|U|X|Z) ((?:0|1|U|X|Z)+) ((?:0|1|U|X|Z)+) ((?:0|1|U|X|Z)+)/i);

				//this.log(i + ": " + lines[i]);

				// If the line matches the format
				if ((matches || []).length > 0) 
				{
					// matches[key] key:
					// 1: sim time
					// 2: sim time units
					// 3: hsync
					// 4: vsync
					// 5: red
					// 6: green
					// 7: blue

					// Assemble data
					sim_time_secs = this.timeConversion(matches[2], "sec", parseInt(matches[1]));
					hsync = parseInt(matches[3]);
					vsync = parseInt(matches[4]);
					red = this.bin_to_color(matches[5]);
					green = this.bin_to_color(matches[6]);
					blue = this.bin_to_color(matches[7]);

					//this.log("sim time: " + sim_time_secs + " - last sim time: " + this.lastPacketTime);
					
					// Now add the time
					this.timeSinceLastPixel += parseFloat((sim_time_secs - this.lastPacketTime).toFixed(20));


					// End of row reached, move to next line
					// Detect the rising edge
					if (this.last_hSync === 0 && hsync == 1) 
					{
						this.hCounter = 0;
						
						// Move to the next row, if past back porch
						if(this.backPorchYCount >= this.backPorchY)
							this.vCounter++;

						
						// Increment this so we know how far we are
						// After the vsync pulse
						this.backPorchYCount++;
						
						
						// Set this to zero so we can count up to the actual
						this.backPorchXCount = 0;
						
						
						// Sync on sync pulse
						this.timeSinceLastPixel = 0;
						
					}

					// vertical limit reached, go to the top
					// Detect rising edge
					if (this.last_vSync === 0 && vsync == 1) 
					{
						this.hCounter = 0;
						this.vCounter = 0;

						// Set this to zero so we can count up to the actual
						this.backPorchYCount = 0;
						
						// Sync on sync pulse
						this.timeSinceLastPixel = 0;
						
						// Add a image to the array for every frame
						this.imageArray.push(this.canvas_manager.createImageData());

						// Update all the frame thumbs
						this.updateFrameThumbs();
					}


					// Don't do anything, if we don't have something to draw on
					// We need to wait for a vsync (where we create a canvas)
					if(this.imageArray.length > 0)
					{
					
						// Add a tolerance so that the timing doesn't have to be bang on
						var tolerance = this.timeConversion("ns", "sec", 5);
						if (this.timeSinceLastPixel >= parseFloat((1 / (this.pixelClockRate * 1000000) - tolerance).toFixed(20)) && this.timeSinceLastPixel <= parseFloat((1 / (this.pixelClockRate * 1000000) + tolerance).toFixed(20))) 
						{
		
								
							// Increment this so we know how far we are
							// After the hsync pulse
							this.backPorchXCount++;
							
							
							// If we are past the back porch
							// Then we can start drawing on the canvas
							if(this.backPorchXCount >= this.backPorchX && this.backPorchYCount >= this.backPorchY)
							{
								// Make sure we don't muddle the canvas with pixels we don't capture
								if (this.hCounter < this.resX && this.vCounter < this.resY) 
								{
									// Add to canvas
									if (this.imageArray.length > 0) {
										this.canvas_manager.setPixel(
											this.imageArray[this.imageArray.length - 1],
											this.hCounter,
											this.vCounter,
											red,
											green,
											blue,
											255 // opaque
										);
									}
								}
			
			
							}
		
							
							
							// Move to the next pixel, if past back porch
							if(this.backPorchXCount >= this.backPorchX)
								this.hCounter++;
							

							
							
							
							
							// Reset time since we dealt with it
							this.timeSinceLastPixel = 0;
		
							//this.log(red + " " + green + " " + blue);
						}
					}

					// Make sure to save this time for next iteration
					this.lastPacketTime = sim_time_secs;
					this.last_hSync = hsync;
					this.last_vSync = vsync;
				}
				else 
					this.numLinesSkipped++;

				lineIndex++;
			}


			// copy the image data back onto the canvas
			if (this.imageArray.length > 0) {


				//this.log("Copying to canvas " + Date.now());
				this.canvas_manager.putImageData(this.imageArray[this.imageArray.length - 1], 0, 0, false);
			}

			// Queue up another call for the next numLinesPerIteration lines
			if (!this.stopHandlingLines && lineIndex < this.file_lines.length - 1) 
			{
				decoder_this = this;

				setTimeout(function () {
					decoder_this.handleLines(lineIndex);
				}, 0);
			}
			else 
			{
				this.handeLinesExecTime = Date.now() - this.handleLinesStartTime;
				this.handleLinesStartTime = -1;

				// Update all the frame thumbs, now that we are done
				this.updateFrameThumbs();

				this.log("Done iterating through all lines: " + Date.now());
				this.log("Iterating through all lines took (ms): " + this.handeLinesExecTime);
			
				
				// Tell them if we got any parsing errors
				$(this.canvas_manager.element).trigger('progressDone', {numLinesSkipped: this.numLinesSkipped});
			}


			// Add progress
			$(this.canvas_manager.element).trigger('progressUpdate', {lineIndex: lineIndex});
		};

		this.updateFrameThumbs = function () {
			// if the frameHolder exists, not null
			if (this.frameHolder.length != 0) 
			{
				for (var f = 0; f < this.imageArray.length; f++) {

					// If the element does not exist
					if ($('#vga-frame-' + f).length === 0) {
						// Create it
						this.frameHolder.append(
							'<div class="vga-frame">' + f + ': <br /><canvas id="vga-frame-' + f + '" class="vga-frame-canvas no-smoothing" data-frame-number="' + f + '"></canvas></div>'
						);
					}


					var frame_canvasMan = new canvasManager();
					frame_canvasMan.init($('#vga-frame-' + f)[0]);

					// Resize canvas onload
					frame_canvasMan.resizeCanvas(this.resX, this.resY);

					// Put the image
					frame_canvasMan.putImageData(
						this.imageArray[f],
						0, // at coords 0,0
						0,
						false // no aliasing
					);


					// Size it down
					frame_canvasMan.resizeCanvas(this.resX / 4, this.resY / 4);
				}
			}

		};


		this.bin_to_color = function (bin) {
			// Returns a value 0-255 corresponding to the bit depth of the binary number and the value.
			// This is why your rgb values need to be padded to the full bit depth

			// (value/bitdepth)*255
			return (parseInt(bin, 2) / parseInt(Array(bin.length).join("1"), 2)) * 255;
		};

		this.timeConversion = function (unitFrom, unitTo, value) {
			// convert between the following:
			// fs, ps, ns, us, ms, sec, min, hr
			// Syntax: timeConversion(ns, sec, 20)
			time_unit_dictionary = {
				"fs": .000000000000001,
				"ps": .000000000001,
				"ns": .000000001,
				"us": .000001,
				"ms": .001,
				"s": 1, // not a supported unit in vhdl, but useful
				"sec": 1,
				"min": 60,
				"hr": 3600,
			};

			return parseFloat(((time_unit_dictionary[unitFrom] / time_unit_dictionary[unitTo]) * value).toFixed(20));
		};
	}



	// Make a new canvas manager
	var my_canvasMan = new canvasManager();
	my_canvasMan.init($('#vga-canvas')[0]);

	// Make a new decoder
	var my_vgaDecoder = new vgaDecoder();
	my_vgaDecoder.init($('#res-x').val(), $('#res-y').val(), $('#px-clk-rate').val(), my_canvasMan);
	my_vgaDecoder.frameHolder = $('#vga-frame-holder');


	// And resize canvas when we change those inputs
	$('#res-x, #res-y').on('input propertychange change', function () {
		my_canvasMan.resizeCanvas($('#res-x').val(), $('#res-y').val());
	}).trigger('change');


	// Update the progress as we go
	$('#vga-canvas').on('progressUpdate', function(e, data) {
		$('#log-form-progress').html((data.lineIndex + 1) + " / " + my_vgaDecoder.file_lines.length);
	});

	// We are done so update the status
	$('#vga-canvas').on('progressDone', function(e, data) {
		if (data.numLinesSkipped > 0) {
			$('#log-form-status').html('Skipped ' + data.numLinesSkipped + ' lines. Error parsing those lines.');
		}
	});

	// When they submit the form process it
	$('#log-form').on('click', 'input[type=submit]', function (e) {
		
		if(this.value == "Stop")
		{
			// This will make the decoder stop asap
			my_vgaDecoder.stopHandlingLines = true;
			
			$('#log-form-status').html("Stopped!");
		}
		else if(this.value == "Submit")
		{
			my_vgaDecoder.restart();

			my_vgaDecoder.resX = $('#res-x').val();
			my_vgaDecoder.resY = $('#res-y').val();
			my_vgaDecoder.pixelClockRate = $('#px-clk-rate').val();


			// Set the backporch according to the range inputs
			my_vgaDecoder.backPorchX = parseInt($('#back-porch-x').val());
			my_vgaDecoder.backPorchY = parseInt($('#back-porch-y').val());
			my_vgaDecoder.stopHandlingLines = false;

			if(my_vgaDecoder.shouldLog)
				console.log("bp x: " + my_vgaDecoder.backPorchX + " - bp y: " + my_vgaDecoder.backPorchY);
		

			// Clear the frames
			$('#vga-frame-holder').empty();
		

			// If they put a file
			if($('#log-file').val())
			{
				var file = $('#log-file').get(0).files[0];
			
				if (file.type == "text/plain") {
					// Tell them the file is being worked on
					$('#log-form-status').html('Working...');
			
					var fr = new FileReader();
			
					// Once the file is read, it will appear here
					fr.onload = function (e) {
						// fr.result or e.target.result should contain the text
						//console.log(e.target.result);
						//console.log(fr.result);
			
						// Go handle the file
						if(my_vgaDecoder.shouldLog)
							console.log("Passing text to the handle function: " + Date.now());
						my_vgaDecoder.handleFileContent(fr.result);
					};
			
					// Read the file
					if(my_vgaDecoder.shouldLog)
						console.log("Start to read file: " + Date.now());
					fr.readAsText(file);
			
				} else {
					$('#log-form-status').html('Not a text file!');
				}
			}
			else {
				$('#log-form-status').html('Please choose a file!');
			}

		}
		
		e.preventDefault();
	});


	// Switch around the frames when we click them
	$('#vga-frame-holder').on('click', '.vga-frame', function () {
		my_canvasMan.putImageData(my_vgaDecoder.imageArray[parseInt($(this).find('.vga-frame-canvas').attr('data-frame-number'))], 0, 0, false);
	});


	// Save the current frame
	$('#download-frame').on('click', function () {
		$(this).attr('href', my_canvasMan.element.toDataURL("image/png"));
		$(this).attr('download', "frame.png");
	});


	// Update the range outputs to display the current value
	$('input[type="range"]').change(function() {
		$('output[for="' + $(this).attr('id') + '"]').html($(this).val());
	}).trigger('change');

});
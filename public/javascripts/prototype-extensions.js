PeriodicalExecuter.prototype.registerCallback = function() {
	this.intervalID = setInterval(this.onTimerEvent.bind(this), this.frequency * 1000);
}

PeriodicalExecuter.prototype.stop = function() {
	clearInterval(this.intervalID);
}
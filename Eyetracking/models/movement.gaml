/**
* Name: movement
* Based on the internal empty template. 
* Author: lilah
* Tags: 
*/


model movement

/* Insert your model definition here */

global torus: true{
    // Global variables related to the Management units	
    float step <- 1 #s;
    
    int n_cyclists <- 20;
    
    list<int> stress_list <- [];
    list<int> speed_list <- [];
    

   
	int counter;
    
    init {
    	create cyclist number: n_cyclists {
    	}
    	create participant number: 1{
    	}
    	
    }
}
// hauptagent, und andere Verkehrsteilnehmer
species participant skills:[moving]{
	geometry action_area <- circle(speed) intersection cone(0, 90);
	geometry perception_area <- circle(speed) intersection cone(0, 214);
	geometry sight_line <- line(self.location, self.location + {0, 10})intersection circle(speed);
	float perception_angle;
	float perception_radius;
	
	float speed <- 5.0;
	float stress <- 4.95; //further research needed, GENDER DIFFERENCES!!!, Stressauslöser nur bei seh r nahem Kontakt, bei crash etc, binär
	
	reflex move {
		do wander;
		//write speed + stress;
				
	}

    
    action stress_change{
    	stress <- 100.0;
    }
    
    action speed_change {
    	speed <- 4.0;
    }
    
    action change_perception{
    	perception_area <- circle(speed) intersection cone(0, 20);
    }
    
    reflex report {
    	write stress_list;
    	write speed_list;
    }
    
    reflex update_actionArea {
		action_area <- circle(speed) intersection cone(heading - 45, heading + 45);
		perception_area <- circle(speed) intersection cone(heading - 107, heading + 107);
		
		sight_line <- line(self.location, self.location + {0, 10})intersection circle(speed);
	}
	
    
    aspect participant {
	// Cyclist is drawn as a 
		draw circle(1) color: #red;
	
	}
	
	aspect action_area {
	draw self.action_area color: #grey;
	}
	
	aspect perception_area {
	draw self.perception_area color: #goldenrod;
	}
	aspect sight_line {
		draw self.sight_line color: #blue ;
	}
    
}

species cyclist skills:[moving]{
	reflex move {
		do wander;
	}

	reflex stress_participant{
		ask participant at_distance (5){
			do action: speed_change;
			do action: stress_change;
			do action: change_perception;
			write "I interacted!";
		}
	}
	
	aspect cyclist {
		draw circle(1) color: #black;
	}
}
experiment main type: gui {	
	parameter "Number of Cyclists on the streets" var:n_cyclists;
    output {
		display  map type:opengl {
	   		species participant aspect: participant;
	   		species participant aspect:action_area transparency: 0.5;
	   		species participant aspect:perception_area transparency: 0.5;
	   		species participant aspect: sight_line;
	   		
	   		species cyclist aspect:cyclist;
		}
    }
}
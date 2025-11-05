/**
* Name: Wumpus World
* Author: Christian Faccio
* Tags: 
*/

model wumpus

global {
	int x <- 25;
	int y <- 25;
	int n_gold <- 1;
	int n_wumpus <- 1;
	int n_pit <- 3;
	int n_players <- 1;
	
	// BELIEFS
	string feel_glitter <- "feel_glitter";
	predicate feel_gold <- new_predicate(feel_glitter);
	string feel_odor <- "feel_odor";
	predicate feel_wumpus <- new_predicate(feel_odor);
	string feel_breeze <- "feel_breeze";
	predicate feel_pit <- new_predicate(feel_breeze);
	
	// DESIRES
	predicate patrol <- new_predicate("patrol");
	predicate collect_gold <- new_predicate("collect_gold");
	predicate avoid_wumpus <- new_predicate("avoid_wumpus");
	predicate avoid_pit <- new_predicate("avoid_pit");
	predicate choose_location <- new_predicate("choose_location");
	 
	init {
		create goldArea number: n_gold;
		create wumpusArea number: n_wumpus;
		create pitArea number: n_pit;
		create player number: n_players;
	}
	
	reflex end_simulation when: (n_players = 0) or (n_gold = 0) {
		do pause;
	}
}


grid gworld width: x height: y neighbors:4 {
	rgb color <- #black;
	list<gworld> neighbors <- (self neighbors_at 1);
}

species odorArea{
	aspect base {
	  draw square(4) color: #brown border: #black;		
	}
}
species glitterArea{
	aspect base {
	  draw square(4) color: #chartreuse border: #black;		
	}
}
species breezeArea{
	aspect base {
	  draw square(4) color: #lightblue border: #black;		
	}
}

species pitArea{
	gworld place <- one_of(gworld);
	init {
		
		location <- place.location;
		
		loop i over: place.neighbors {
			create breezeArea{
				location <- i.location;
			}
		}
	
	}
	
	aspect base {
	  draw square(4) color: #blue border: #black;		
	}
}
species wumpusArea{
	image_file icon <- image_file('../includes/wumpus.png');
	gworld place <- one_of(gworld);
	init {
		
		location <- place.location;
		
		loop i over: place.neighbors {
			create odorArea{
				location <- i.location;
			}
		}
	}
	aspect base {
	  draw square(4) color: #red border: #black;		
	}
	aspect icon {
		draw icon size: 4.0;
	}
}
species goldArea{
	image_file icon <- image_file('../includes/gold.jpg');
	gworld place <- one_of(gworld);
	list<glitterArea> my_glitters <- [];  // Track created glitters
	
	init {
		
		location <- place.location;
		
		loop i over: place.neighbors {
			create glitterArea{
				location <- i.location;
				myself.my_glitters << self;
			}
		}
	}
	
	aspect base {
	  draw square(4) color: #yellow border: #black;		
	}
	aspect icon {
		draw icon size: 4.0;
	}
}

species player skills:[moving] control: simple_bdi {
	
	gworld place <- one_of(gworld);
	
	// BDI params --------------------------------------------------------------------------------------
	
	point target;
	list<point> memory <- [];		// defines the memory of the player 
	
	// Init --------------------------------------------------------------------------------------
	
	init {
		location <- place.location;
		//memory <+ place.location; // needed for ADVANCED concepts
		
		do add_desire(patrol); // initialize agent with desire to go around (patrol)
	}
	
	// Reflexes --------------------------------------------------------------------------------------
	

	
	// Perceptions --------------------------------------------------------------------------------------
	
	perceive gold target: goldArea in: 0.1 {
	    list<glitterArea> glitters_to_remove <- self.my_glitters;
	    
	    ask myself {
	        do remove_belief(feel_gold);
	        do remove_intention(collect_gold, false);
	        n_gold <- n_gold - 1;
	        memory <- [];
	        do add_desire(patrol);
	    }
	    
	    ask glitters_to_remove {
	        do die;
	    }
	    
	    do die;  
	}
	perceive wumpus target: wumpusArea in: 0.1{
		ask myself {
			n_players <- 0;
			do die;
		}
	}
	perceive pit target: pitArea in: 0.1{
		ask myself {
			n_players <- 0;
			do die;
		}
	}
	perceive glitter target: glitterArea in: 0.1{
		focus id: feel_glitter;
		ask myself {
			do remove_intention(patrol, false);
		}
	}
	perceive odor target: odorArea in: 0.1{
		focus id: feel_odor; 
		ask myself {
			do remove_intention(patrol, false);
		}
	}
	perceive breeze target: breezeArea in: 0.1{
		focus id: feel_breeze;
		ask myself {
			do remove_intention(patrol, false);
		}
	}
	
	// Rules --------------------------------------------------------------------------------------
	
	// TODO: check for strength correctness
	rule belief: feel_gold new_desire: collect_gold strength: 3.0;
	rule belief: feel_pit new_desire: avoid_pit strength: 1.0;
	rule belief: feel_wumpus new_desire: avoid_wumpus strength: 2.0;
	
	// Plans --------------------------------------------------------------------------------------
	
	plan move_random intention: patrol {
		gworld new_place <- one_of(place.neighbors); // random selection from the neighbors
		place <- new_place;
		location <- new_place.location;
		//memory <+ location;
	}
	plan get_gold intention: collect_gold {
	    if (length(memory) = 0) {
	        loop neighbor over: place.neighbors {
	            memory <+ neighbor.location;
	        }
	    }
	    
	    if (length(memory) > 0) {
	        point next_location <- memory[0];
	        place <- gworld(next_location);  
	        location <- next_location;        
	        memory >- first(memory);          
	    } else {
	        do remove_belief(feel_gold);
	        do remove_intention(collect_gold, false);
	        do add_desire(patrol);
	    }
	}
	plan escape_pit intention: avoid_pit {
		
	}
	plan escape_wumpus intention: avoid_wumpus {
		
	}
	
	// Aspect --------------------------------------------------------------------------------------
	
	aspect base {
		draw circle(1) color: #white;
	}
}

experiment Wumpus_experiment_1 type: gui {
	parameter "Grid x:" var: x min: 0 max: 1000;
	parameter "Grid y:" var: y min: 0 max: 1000;
	parameter "Number of gold spots:" var: n_gold min: 1;
	parameter "Number of wumpuses:" var: n_wumpus min: 0;
	parameter "Number of pits:" var: n_pit min: 0;
	
	output {					
		display view1 { 
			grid gworld border: #white;
			species goldArea aspect:icon;
			species glitterArea aspect:base;
			species wumpusArea aspect:icon;
			species odorArea aspect:base;
			species pitArea aspect:base;
			species breezeArea aspect: base;
			species player aspect: base;
		}
	}
}

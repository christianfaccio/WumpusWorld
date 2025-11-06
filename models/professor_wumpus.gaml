model Wumpus_template

global {
    int total_gold <- 3;
    int total_gold_collected <- 0;
    
    init {
        create goldArea number:total_gold;
        create player number:1;
    }
    
    predicate belief_patrol <- new_predicate("belief_patrol");
    predicate belief_glitter <- new_predicate("belief_glitter");
    
    predicate desire_patrol <- new_predicate("desire_patrol");
    predicate desire_pursue_gold <- new_predicate("desire_pursue_gold");
}

grid gworld width: 25 height: 25 neighbors:4 {
    rgb color <- #green;
}

species player skills: [moving] control: simple_bdi {
    gworld place <- one_of(gworld);
    gworld previous;
    
    init {
        location <- place.location;
        do add_belief(belief_patrol);
    }
    
    aspect base {
        draw circle(2) color: #magenta border: #black;
    }
    
    // perceive glitter
    perceive target:glitterArea in: 1 {
        write "perceive: glitter";
        ask myself{
	        do remove_belief(belief_patrol);
	        do add_belief(belief_glitter);
        }
    }
    
    // perceive gold
    perceive target:goldArea in: 0 {
        write "perceive: gold";
        loop g over: goldArea {
            if(!g.collected and g.location = location) {
                g.collected <- true;
                total_gold_collected <- total_gold_collected + 1;
                write "gold: collected " + location;
                
                // check if all gold is collected
                if (total_gold_collected = total_gold) {
                    ask world { do pause; }
                }
                
                // go back to patrol
                ask myself {
	                do remove_belief(belief_glitter);
	                do add_belief(belief_patrol);
                }
                
                // remove gold and glitter
                    
		        ask glitterArea at_distance 4 {
                	do die;
            	}
                ask g { do die; }
            }
        }
    }
    
    // keep patrol when there's no glitter
    rule belief: belief_patrol new_desire: desire_patrol;
    
    // pursue gold when glitter is detected
    rule belief: belief_glitter new_desire: desire_pursue_gold;
    
    // plan: "normal" patrol
    plan patrol intention: desire_patrol {
        write "plan: patrol";
        list<gworld> possible_moves <- place.neighbors - previous;
        if (empty(possible_moves)) {
            possible_moves <- place.neighbors;
        }
        gworld new_place <- one_of(possible_moves);
        
        previous <- place;
        place <- new_place;
        location <- new_place.location;
    }
    
    // plan: approach gold when glitter is detected
    plan pursue_gold intention: desire_pursue_gold {
        write "plan: pursue gold";
        gworld new_place <- one_of(place.neighbors - previous);
                
        previous <- place;
        place <- new_place;
        location <- new_place.location;
    }
}

species glitterArea {
    aspect base {
        draw square(4) color: #chartreuse border: #black;
    }
}

species goldArea {
    bool collected <- false;
    
    init {
        gworld place <- one_of(gworld);
        location <- place.location;
        
        list<gworld> my_neighbors <- [];
        ask place {
            my_neighbors <- neighbors;
        }
        
        loop i over: my_neighbors {
            create glitterArea {
                location <- i.location;
            }
        }
    }
    
    aspect base {
        draw square(4) color: #yellow border: #black;
    }
}

experiment Wumpus_experiment_1 type: gui {
    output {
        display view1 {
            grid gworld border: #darkgreen;
            species goldArea aspect:base;
            species glitterArea aspect:base;
            species player aspect:base;
        }
    }
}
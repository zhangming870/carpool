import {ADD_ONE} from './action-types'


const initstate = {whatever:"aaa"}


export function addOne(state=initstate, action){
    switch (action.type) {
        case ADD_ONE:
            
            return {whatever:action.data};
    
        default:
            return state;
    }

}
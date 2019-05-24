import {ADD_ONE,Minus_ONE} from './action-types'
import {combineReducers} from 'redux'

const initstateaddnumber = {addnumber:0}
const initminus = {minusnumber:100}


function addOneReducer(state=initstateaddnumber, action){
    switch (action.type) {
        case ADD_ONE:
            return {...state, addnumber:state.addnumber + action.data}
        default:
            return state;
    }

}

function minusOneReducer(state=initminus, action){
    switch (action.type) {
        case Minus_ONE:
            
        return {...state, minusnumber:state.minusnumber - action.data}
    
        default:
            return state;
    }

}

export default combineReducers({
    minusOneReducer, addOneReducer
})
import {ADD_ONE} from './action-types'

export const addone= (abc)=> ({type:ADD_ONE, data: abc})

export const addoneAsync = (abc)=> {

    return dispatch => {

        setTimeout(() => {
            dispatch(addone(abc))
        }, 1000);
    }
}
import React from 'react';
import './App.css';
import Sidebar from "react-sidebar";
import { Jumbotron, Container } from 'react-bootstrap';
import Bigarea from '../../components/bigarea/Bigarea'

import {connect} from 'react-redux'
import {addone} from '../../redux/actions'

class App extends React.Component {

  changeAAAHandler = (e)=> {

    this.props.addone()
  }


  render() {


    const {whatever} = this.props




    return (
      <div>


        <Jumbotron fluid>
          <Container>
            <h1>{whatever}</h1>
            <p>
              <button onClick={this.changeAAAHandler}>change aaa</button>
            </p>
          </Container>
        </Jumbotron>
        <Bigarea></Bigarea>





      </div>

    )
  }
}

export default connect(
  state => ({whatever:state.whatever}),
  {addone}
)(App);
